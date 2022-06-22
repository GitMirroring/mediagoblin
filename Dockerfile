ARG build_doc=false
ARG build_dist=false
ARG run_tests=true

ARG audio_support=true
ARG video_support=true
ARG raw_image_support=true
ARG pdf_support=true
ARG document_support=false
ARG stl_support=false
ARG ldap_support=true

FROM debian:bullseye-slim AS base
ARG audio_support
ARG video_support
ARG raw_image_support
ARG pdf_support
ARG document_support
ARG stl_support
ARG ldap_support

# We don't install -dev packages in the base image, so they don't pull down
# build tools unecessary at runtime.
# We install them separately in the builder stage.
# The drawback of this is that we need to specify the ABI version of each
# library we need, as there are no unversioned metapackage depending on them the
# way the -dev ones do.
RUN DEBIAN_FRONTEND=noninteractive apt-get update \
	    && apt-get install --no-install-recommends -y \
	    curl \
	    sqlite3 \
	    python3-venv \
# Those get installed automatically in the builder, so end up missing in the
# venv, and the final image, if not installed here
	    python3-markdown \
	    python3-mako \
# Install audio dependencies.
	    $(test "${audio_support}" = 'false' \
			    && test "${video_support}" = 'false' || echo '\
		    gstreamer1.0-libav \
		    gstreamer1.0-plugins-base \
		    gstreamer1.0-plugins-bad \
		    gstreamer1.0-plugins-good \
		    gstreamer1.0-plugins-ugly \
		    python3-gst-1.0\n\
	    ') \
# Install video dependencies.
	    $(test "${video_support}" = 'false' || echo '\
		    gir1.2-gst-plugins-base-1.0 \
		    gir1.2-gstreamer-1.0 \
		    gstreamer1.0-tools \
		    libcairo2 \
		    libgirepository-1.0-1 \
	    ') \
# Install raw image dependencies.
	    $(test "${raw_image_support}" = 'false' || echo '\
		    libboost-python1.74.0 \
		    libexiv2-27 \
	    ') \
# Install document (PDF-only) dependencies.
	    $(test "${pdf_support}" = 'false' || echo '\
		    poppler-utils \
	    ') \
	    $(test "${document_support}" = 'false' || echo '\
		    unoconv \
	    ') \
# For STL files
	    $(test "${stl_support}" = 'false' || echo '\
		    blender \
	    ') \
# For python-ldap
	    $(test "${ldap_support}" = 'false' || echo '\
		    libldap-2.4-2 \
		    libsasl2-2 \
	    ') \
	    && rm -rf /var/lib/apt/lists/*

RUN groupadd --system mediagoblin \
	    && useradd --gid mediagoblin --home-dir /srv/mediagoblin mediagoblin

RUN mkdir /opt/mediagoblin \
	&& chown -R www-data:www-data /opt/mediagoblin

WORKDIR /opt/mediagoblin

FROM base AS builder
ARG build_doc
ARG build_dist

ARG audio_support
ARG video_support
ARG raw_image_support
ARG pdf_support
ARG document_support
ARG stl_support
ARG ldap_support

RUN DEBIAN_FRONTEND=noninteractive apt-get update \
	    && apt-get install --no-install-recommends -y \
	    git \
	    python3-dev \
	    pkg-config \
	    npm \
	    $(test "${audio_support}" = 'false' \
	    && test "${video_support}" = 'false' || echo '\
		    libglib2.0-dev \
		    libgstreamer1.0-dev \
		    libgstreamer-plugins-base1.0-dev \
		    libgirepository1.0-dev \
		    libcairo-dev \
	    ') \
	    $(test "${raw_image_support}" = 'false' || echo '\
		    libexiv2-dev \
		    libboost-python-dev \
	    ') \
	    $(test "${ldap_support}" = 'false' || echo '\
		    libsasl2-dev \
		    libldap2-dev \
	    ') \
	    && rm -rf /var/lib/apt/lists/* \
	    && npm install -g bower

# Create /var/www because Bower writes some cache files into /var/www during
# make, failing if it doesn't exist.
RUN mkdir --mode=g+w /var/www \
	&& chown www-data:www-data /var/www

USER www-data

# Set up custom group to align with volume permissions for mounted
# "mediagoblin/mediagoblin" and "mediagoblin/user_dev".
#
# The problem here is that the host's UID, GID and mode are used in the
# container, but of course the container's user www-data is running under a
# different UID/GID so can't read or write to the volume. It seems like there
# should be a better approach, but we'll align volume permissions between host
# and container as per
# https://medium.com/@nielssj/docker-volumes-and-file-system-permissions-772c1aee23ca

# Copy upstream MediaGoblin into the image for use in the build process.
#
# This build process is somewhat complicated, because of Bower/NPM, translations
# and Python dependencies, so it's not really feasible just to copy over a
# requirements.txt like many Python Dockerfiles examples do. We need the full
# source.
#
# While it is possible to copy the source from the current directory like this:
#
COPY --chown=www-data:www-data . /opt/mediagoblin
#
# that approach to lots of confusing problems when your working directory has
# changed from the default - say you've enabled some plugins or switched
# database type. So instead we're doing a git clone. We could potentially use
# `git archive` but this still wouldn't account for the submodules.
#
# TODO: Figure out a docker-only way to do the build and run from our local
# version, so that local changes are immediately available to the running
# container. Not as easy as it sounds. We have this working with docker-compose,
# but still uses upstream MediaGoblin for the build.
# RUN git clone --depth=1 git://git.savannah.gnu.org/mediagoblin.git --branch master .
# RUN git clone --depth=1 https://gitlab.com/BenSturmfels/mediagoblin.git --branch master .
# RUN git show --oneline --no-patch

# RUN ./bootstrap.sh \
#     && ./configure \
#     && make


RUN ./configure \
	&& make build \
	&& rm -rf ~/.cache/pip

# Build the documentation.
RUN test "${build_doc}" = 'false' \
	|| make docs

# Build a wheel
RUN test "${build_dist}" = 'false' \
	|| make dist

FROM base AS runner
ARG run_tests

# RUN DEBIAN_FRONTEND=noninteractive apt-get -y remove 'lib.*-dev' \
#	&& rm -rf /var/lib/apt/lists/*

COPY --from=builder /opt/mediagoblin /opt/mediagoblin
COPY entrypoint.sh /opt/mediagoblin
COPY lazyserver.sh /opt/mediagoblin

# Run the tests in the final container.
# We can't use make here, as it's not actually installed.
RUN test "${run_tests}" = 'false' \
	|| ( ./venv/bin/pip install .[test] \
		&& ./venv/bin/python -m pytest)

VOLUME [ "/srv" ]

WORKDIR /srv

EXPOSE 6543/tcp

ENTRYPOINT ["/opt/mediagoblin/entrypoint.sh"]

HEALTHCHECK \
  CMD curl -f http://localhost:6543/ || exit 1

# TODO: Is it possible to have a CMD here that is overriden by docker-compose?
CMD ["/opt/mediagoblin/lazyserver.sh",  "-c", "./paste.ini", "--server-name=broadcast" ]
