ARG build_doc=false
ARG run_tests=true

FROM debian:bullseye AS base

RUN DEBIAN_FRONTEND=noninteractive apt-get update \
	    && apt-get install -y \
	    curl \
	    python3-dev \
	    python3-venv \
# Install audio dependencies.
	    gstreamer1.0-libav \
	    gstreamer1.0-plugins-bad \
	    gstreamer1.0-plugins-base \
	    gstreamer1.0-plugins-good \
	    gstreamer1.0-plugins-ugly \
	    python3-gst-1.0 \
# Install video dependencies.
	    gir1.2-gst-plugins-base-1.0 \
	    gir1.2-gstreamer-1.0 \
	    gstreamer1.0-tools \
# Install raw image dependencies.
#
# Currently (March 2021), python3-py3exiv2 is only available in Debian Sid, so
# we need to install py3exiv2 from PyPI (later on in this Dockerfile). These are
# the build depedencies for py3exiv2.
	    libexiv2-dev \
	    libboost-python-dev \
# Install document (PDF-only) dependencies.
# TODO: Check that PDF tests aren't skipped.
	    poppler-utils \
# To build pygobject
	    libglib2.0-dev \
	    # gobject-introspection \
	    libgirepository1.0-dev \
# To build python-ldap
	    libsasl2-dev \
	    libldap2-dev \
# To build pycairo
	    libcairo-dev

RUN groupadd --system mediagoblin \
	    && useradd --gid mediagoblin --home-dir /srv/mediagoblin mediagoblin

RUN mkdir /opt/mediagoblin \
	&& chown -R www-data:www-data /opt/mediagoblin


FROM base AS builder
ARG build_doc
ARG run_tests

RUN DEBIAN_FRONTEND=noninteractive apt-get update \
	    && apt-get install -y \
	    pkg-config \
	    nodejs \
	    npm \
	    && rm -rf /var/lib/apt/lists/*

RUN npm install -g bower

# Create /var/www because Bower writes some cache files into /var/www during
# make, failing if it doesn't exist.
RUN mkdir --mode=g+w /var/www
RUN chown www-data:www-data /var/www

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

WORKDIR /opt/mediagoblin

RUN bower install; rm -rf ~/.bower

RUN python3 -m venv --system-site-packages venv \
	    && ./venv/bin/pip install \
	    . \
	    .[dev] \
	    $(test "${run_tests}" = 'false' || echo '.[test]') \
	    .[ldap] \
	    .[openid] \
# Additional Sphinx dependencies
	    $(test "${build_doc}" = 'false' || echo '.[doc]') \
# Install raw image library from PyPI.
# RUN ./bin/pip install \
# py3exiv2 \
	    .[image] \
	    .[audio] \
	    .[video]; \
	    rm -rf ~/.cache/pip

# RUN pip install .

RUN ./devtools/compile_translations.sh

# Confirm our packages version for later troubleshooting.
# RUN ./bin/python -m pip freeze

# Run the tests.
RUN test "${run_tests}" = 'false' \
	|| ./venv/bin/python -m pytest

# Build the documentation.
RUN test "${build_doc}" = 'false' \
	|| make -C docs html SPHINXBUILD=../venv/bin/sphinx-build


FROM base AS runner

# RUN DEBIAN_FRONTEND=noninteractive apt-get -y remove 'lib.*-dev' \
#	&& rm -rf /var/lib/apt/lists/*
RUN rm -rf /var/lib/apt/lists/*

# COPY --from=builder /opt/mediagoblin/venv /opt/mediagoblin
COPY --from=builder /opt/mediagoblin /opt/mediagoblin
COPY entrypoint.sh /opt/mediagoblin
COPY lazyserver.sh /opt/mediagoblin

VOLUME [ "/srv" ]

WORKDIR /srv

EXPOSE 6543/tcp

ENTRYPOINT ["/opt/mediagoblin/entrypoint.sh"]

HEALTHCHECK \
  CMD curl -f http://localhost:6543/ || exit 1

# TODO: Is it possible to have a CMD here that is overriden by docker-compose?
CMD ["/opt/mediagoblin/lazyserver.sh",  "-c", "./paste.ini", "--server-name=broadcast" ]
