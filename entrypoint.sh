#!/bin/sh -eu

ADMIN_USER=${ADMIN_USER:-admin}
ADMIN_PASSWORD=${ADMIN_PASSWORD:-overrideme}
ADMIN_EMAIL=${ADMIN_EMAIL:-admin@example.com}

CELERY_ALWAYS_EAGER=${CELERY_ALWAYS_EAGER:-false}
BROKER_URL=${BROKER_URL:-}
PLUGINS=${PLUGINS:-[[mediagoblin.plugins.geolocation]]\\n[[mediagoblin.plugins.basic_auth]]\\n[[mediagoblin.plugins.processing_info]]\\n[[mediagoblin.media_types.image]]\\n[[mediagoblin.media_types.audio]]\\n[[mediagoblin.media_types.video]]}

# TODO:
# sql_engine = postgresql:///mediagoblin
# email_sender_address = "notice@mediagoblin.example.org"
# email_debug_mode = true
# email_smtp_host = ""
# email_smtp_port = 0
# allow_registration = true
# allow_reporting = true

MG_PATH="$(dirname "${0}")"
DB=mediagoblin.db
MG_CONFIG=mediagoblin.ini
PASTE_CONFIG=paste.ini
VENV_PATH="${MG_PATH}"/venv

GMG=gmg

usermod -u "${USERMAP_UID:-$(id -u mediagoblin)}" mediagoblin
groupmod -o -g "${USERMAP_UID:-$(id -g mediagoblin)}" mediagoblin
chown mediagoblin:mediagoblin /srv

log () {
	echo "${*}" >&2
}

sudo () {
	USER=${1}
	shift
	CMD="${@}"
	su "${USER}" -c "${CMD}"
}

. "${VENV_PATH}/bin/activate"

for CONFIG in $PASTE_CONFIG $MG_CONFIG; do
	if [ ! -e "${CONFIG}" ]; then
		log "Creating missing configuration file ${CONFIG} ..."
		sudo mediagoblin cp "${MG_PATH}/${CONFIG}" "${CONFIG}"
		SKIP_RECONFIG=false
	fi
done

if [ "${SKIP_RECONFIG:-true}" = "true" ]; then
	log "Skipping reconfiguration ..."
else

	if [ -n "${BROKER_URL}" ] &&
		[ "${CELERY_ALWAYS_EAGER}" = "false" ]; then
		log "Setting broker to ${BROKER_URL} ..."
		sed -i "/\\[celery\\]/,/^$/c\
[celery]\\
BROKER_URL = ${BROKER_URL}\\
" "${MG_CONFIG}"
	fi

	log "Configuring plugins ..."
	sed -i '/\[plugins\]/,$d' ${MG_CONFIG}
	echo "[plugins]\n${PLUGINS}" \
		| sed 's/\\n/\n/' \
		>> "${MG_CONFIG}"
fi

if [ "${SKIP_MIGRATE:-false}" = "true" ]; then
	log "Skipping setup/migration tasks ..."
else
	if [ ! -e "${DB}" ]; then
		log "Creating empty database ${DB} ..."
		sudo mediagoblin touch "${DB}"
		MAKE_ADMIN=true
	fi

	sudo mediagoblin ${GMG} dbupdate
	sudo mediagoblin ${GMG} assetlink

	if [ "${MAKE_ADMIN:-false}" = "true" ]; then
		log "Creating admin user ..."
		${GMG} adduser \
			--username "${ADMIN_USER}"\
			--password "${ADMIN_PASSWORD}"\
			--email "${ADMIN_EMAIL}" \
			&& ${GMG} makeadmin "${ADMIN_USER}"
	fi
fi

log "Running ${*} ..."
sudo mediagoblin exec "${@}"
