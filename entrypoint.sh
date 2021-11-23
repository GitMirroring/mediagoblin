#!/bin/sh -eux

ADMIN_USER=${ADMIN_USER:-admin}
ADMIN_PASSWORD=${ADMIN_PASSWORD:-overrideme}
ADMIN_EMAIL=${ADMIN_EMAIL:-admin@example.com}

MG_PATH="$(dirname "${0}")"
DB=mediagoblin.db
MG_CONFIG=mediagoblin.ini
PASTE_CONFIG=paste.ini
VENV_PATH="${MG_PATH}"/venv

GMG=gmg

usermod -u "${USERMAP_UID:-$(id -u mediagoblin)}" mediagoblin
groupmod -o -g "${USERMAP_UID:-$(id -g mediagoblin)}" mediagoblin

sudo () {
	USER=${1}
	shift
	CMD="${@}"
	su "${USER}" -c "${CMD}"
}

. "${VENV_PATH}/bin/activate"

if [ "${SKIP_MIGRATE:-false}" = "false" ]; then
	for CONFIG in $PASTE_CONFIG $MG_CONFIG; do
	if [ ! -e "${CONFIG}" ]; then
		echo "Creating missing configuration file ${CONFIG}..." >&2
		sudo mediagoblin cp "${MG_PATH}/${CONFIG}" "${CONFIG}"
	fi

	done

	if [ ! -e "${DB}" ]; then
		echo "Creating empty database ${DB}..." >&2
		sudo mediagoblin touch "${DB}"
		MAKE_ADMIN=true
	fi

	sudo mediagoblin ${GMG} dbupdate
	sudo mediagoblin ${GMG} assetlink

	if [ "${MAKE_ADMIN:-false}" = "true" ]; then
		echo "Creating admin user..." >&2
		${GMG} adduser \
			--username "${ADMIN_USER}"\
			--password "${ADMIN_PASSWORD}"\
			--email "${ADMIN_EMAIL}" \
			&& ${GMG} makeadmin "${ADMIN_USER}"
	fi
fi

sudo mediagoblin exec "${@}"
