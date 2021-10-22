#!/bin/sh -eux

ADMIN_USER="admin"
ADMIN_PASSWORD=a
ADMIN_EMAIL=admin@example.com
PLUGINS="\
	mediagoblin.media_types.audio \
	mediagoblin.media_types.video \
	mediagoblin.media_types.raw_image \
	mediagoblin.media_types.pdf \
	"

VENV_PATH=./venv
GMG=gmg
CONFIG=mediagoblin.ini

. ${VENV_PATH}/bin/activate


if [ ! -e ${CONFIG} ]; then
	grep -q "plugins" "${CONFIG}" \
		echo '[plugins]' >> "${CONFIG}"
	for P in ${PLUGINS}; do
		grep -q "${P}" "${CONFIG}" \
			|| echo "[[${P}]]" >> "${CONFIG}"
	done
fi

${GMG} dbupdate
${GMG} adduser \
	--username "${ADMIN_USER}"\
	--password "${ADMIN_PASSWORD}"\
	--email "${ADMIN_EMAIL}" \
	&& ${GMG} makeadmin "${ADMIN_USER}" \
	|| true

exec "${@}"
