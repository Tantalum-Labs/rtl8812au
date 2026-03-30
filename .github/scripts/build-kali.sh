#!/usr/bin/env bash

set -euo pipefail

target="${1:?usage: $0 <rolling|archived-6.12.38>}"

if [[ "$(id -u)" -ne 0 ]]; then
	echo "This script must run as root inside a Kali container." >&2
	exit 1
fi

export DEBIAN_FRONTEND=noninteractive

cat >/etc/apt/sources.list <<'EOF'
deb http://archive.kali.org/kali kali-rolling main contrib non-free non-free-firmware
EOF

apt-get update
apt-get install -y bc build-essential ca-certificates kmod libelf-dev pahole wget

KVER=""
KSRC=""
jobs="${JOBS:-1}"

case "${target}" in
rolling)
	apt-get install -y linux-headers-amd64
	shopt -s nullglob
	modules=(/lib/modules/*)
	shopt -u nullglob
	if [[ "${#modules[@]}" -ne 1 ]]; then
		echo "Expected exactly one installed kernel header tree, found ${#modules[@]}." >&2
		exit 1
	fi
	KVER="$(basename "${modules[0]}")"
	;;
archived-6.12.38)
	archive_base="http://archive.kali.org/kali/pool/main/l/linux"
	wget -q "${archive_base}/linux-kbuild-6.12.38%2Bkali_6.12.38-1kali1_amd64.deb"
	wget -q "${archive_base}/linux-headers-6.12.38%2Bkali-common_6.12.38-1kali1_all.deb"
	wget -q "${archive_base}/linux-headers-6.12.38%2Bkali-amd64_6.12.38-1kali1_amd64.deb"

	# Kali's archived 6.12 headers expect a gcc-14-prefixed compiler binary.
	ln -sf /usr/bin/gcc /usr/local/bin/x86_64-linux-gnu-gcc-14

	dpkg-deb -x linux-kbuild-6.12.38+kali_6.12.38-1kali1_amd64.deb /
	dpkg-deb -x linux-headers-6.12.38+kali-common_6.12.38-1kali1_all.deb /
	dpkg-deb -x linux-headers-6.12.38+kali-amd64_6.12.38-1kali1_amd64.deb /

	KVER="6.12.38+kali-amd64"
	KSRC="/usr/src/linux-headers-${KVER}"
	;;
*)
	echo "Unknown target: ${target}" >&2
	exit 1
	;;
esac

echo "Building against ${KVER}"

make clean

if [[ -n "${KSRC}" ]]; then
	make -j"${jobs}" KVER="${KVER}" KSRC="${KSRC}"
else
	make -j"${jobs}" KVER="${KVER}"
fi
