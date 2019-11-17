#!/usr/bin/env sh

set -e

if [ $# -eq 0 ]; then
  echo "Usage: $(basename $0) <source image file | directory | compressed data file>"
  exit 1
fi

pushd "$(dirname $0)" >/dev/null
source ./env.sh

device=$(losetup -Pf --show "${filename}")
yes | mkfs.ext4 -O uninit_bg,^64bit,^metadata_csum ${device}p2
mkdir -p "${datadir}"
mount -o noatime,nodiratime,rw ${device}p2 "${datadir}"
mkdir -p "${datadir}/local"

# create a 512M swap file
dd if=/dev/zero of="${datadir}/local/swap.img" bs=4M count=128
chmod 0600 "${datadir}/local/swap.img"
mkswap "${datadir}/local/swap.img"

for arg in "$@"; do
  if [[ -f "${arg}" ]]; then
    filetype=$(file -b "${arg}")
    if [[ "$filetype" =~ compressed ]]; then
      cat "${arg}" | bsdtar xf - -C "${datadir}" --strip-components=1
    elif [[ "$filetype" =~ partition ]]; then
      device_src=$(losetup -Pf --show "${arg}")
      mkdir -p "${tmpdir}"
      mount -o ro ${device_src}p2 "${tmpdir}"
      cp -Rf "${tmpdir}/." "${datadir}/"
      umount -l "${tmpdir}"
      rm -rf "${tmpdir}"
      losetup -d ${device_src}
    elif [[ "$filetype" =~ Squashfs ]]; then
      fn=$(basename ${arg})
      cp -f "${arg}" "${datadir}/apps/${fn}"
      chmod 0755 "${datadir}/apps/${fn}"
    fi
  elif [[ -d "${arg}" ]]; then
    cp -Rf "${arg}/." "${datadir}/"
  fi
done

set +e
rm -f "${datadir}/.partition_resized"
# Zero fill disk buffers, to make better compression rates
cat /dev/zero >"${datadir}/zero.fill" 2>/dev/null
sync
sleep 1
sync
rm -f "${datadir}/zero.fill"
sync

umount -l "${datadir}"
rm -rf "${datadir}"
losetup -d ${device}

popd >/dev/null
