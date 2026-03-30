#!/bin/sh

set -eu

SCRIPT_NAME="$(basename "$0")"
BLACKLIST_FILE="${CONFLICT_BLACKLIST_FILE:-/etc/modprobe.d/8812au-blacklist.conf}"
CONFLICT_MODULES="rtw88_8812au rtw88_8821au"

usage() {
	echo "Usage: sudo ./${SCRIPT_NAME} {install|remove|status}" >&2
	exit 1
}

require_root() {
	if [ "$(id -u)" -ne 0 ]; then
		echo "You must run this script as root." >&2
		exit 1
	fi
}

install_blacklist() {
	install -d "$(dirname "${BLACKLIST_FILE}")"
	{
		echo "# Installed by rtl8812au conflict helper"
		echo "# Prevent the in-kernel rtw88 USB drivers from claiming supported devices first."
		for module in ${CONFLICT_MODULES}; do
			echo "blacklist ${module}"
		done
	} > "${BLACKLIST_FILE}"

	echo "Wrote ${BLACKLIST_FILE}:"
	cat "${BLACKLIST_FILE}"
}

remove_blacklist() {
	rm -f "${BLACKLIST_FILE}"
	echo "Removed ${BLACKLIST_FILE}"
}

status_blacklist() {
	if [ -f "${BLACKLIST_FILE}" ]; then
		echo "${BLACKLIST_FILE} exists:"
		cat "${BLACKLIST_FILE}"
	else
		echo "${BLACKLIST_FILE} does not exist."
	fi

	echo
	echo "Loaded conflict modules:"
	lsmod | awk 'NR==1 || $1=="rtw88_8812au" || $1=="rtw88_8821au"'
}

case "${1:-}" in
	install)
		require_root
		install_blacklist
		;;
	remove)
		require_root
		remove_blacklist
		;;
	status)
		status_blacklist
		;;
	*)
		usage
		;;
esac
