#!/usr/bin/env sh

set -e

if [ $# -eq 0 ]; then
  echo "Usage: $(basename $0) <source image file | directory | compressed data file>"
  exit 1
fi

pushd "$(dirname $0)" >/dev/null
source ./env.sh

device=$(losetup -Pf --show "${filename}")
yes | mkfs.ext4 ${device}p2
mkdir -p "${datadir}"
mount -o noatime,nodiratime,rw ${device}p2 "${datadir}"

if [[ -f "$1" ]]; then
  if [[ $(file -b "$1") =~ compressed ]]; then
    cat "$1" | bsdtar xf - -C "${datadir}" --strip-components=1
  else
    device_src=$(losetup -Pf --show "$1")
    mkdir -p "${tmpdir}"
    mount -o ro ${device_src}p2 "${tmpdir}"
    cp -af "${tmpdir}/." "${datadir}/"
  fi
elif [[ -d "$1" ]]; then
  cp -af "$1/." "${datadir}/"
fi

set +e
# Zero fill disk buffers, to make better compression rates
cat /dev/zero >"${datadir}/zero.fill"
sync
sleep 1
sync
rm -f "${datadir}/zero.fill"
sync

umount -l "${datadir}"
rm -rf "${datadir}"
losetup -d ${device}
if [[ -d "${tmpdir}" ]]; then
  umount -l "${tmpdir}"
  rm -rf "${tmpdir}"
  losetup -d ${device_src}
fi

popd >/dev/null
