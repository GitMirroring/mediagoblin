#!/bin/sh

ADMIN_USER=admin
ADMIN_PASSWORD=a
ADMIN_EMAIL=admin@example.com
PLUGINS=\
	mediagoblin.media_types.audio \
	mediagoblin.media_types.video \
	mediagoblin.media_types.raw_image \
	mediagoblin.media_types.pdf \
	#END

CONFIG=mediagoblin_local.ini

touch "${CONFIG}"

for P in ${PLUGINS}; do
	if ! grep "${P}" "${CONFIG}"
		echo "[[${P}]]" >> "${CONFIG}"
	fi
done

RUN ./bin/gmg dbupdate
RUN ./bin/gmg adduser \
	--username "${ADMIN_USER}"\
	--password "${ADMIN_PASSWORD}"\
	--email "${ADMIN_EMAIL}"
RUN ./bin/gmg makeadmin "${ADMIN_USER}"

exec "@{@}"
