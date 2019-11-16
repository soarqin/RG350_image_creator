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

for arg in "$@"; do
  if [[ -f "${arg}" ]]; then
    filetype=$(file -b "${arg}")
    if [[ "$filetype" =~ compressed ]]; then
      cat "${arg}" | bsdtar xf - -C "${datadir}" --strip-components=1
    elif [[ "$filetype" =~ partition ]]; then
      device_src=$(losetup -Pf --show "${arg}")
      mkdir -p "${tmpdir}"
      mount -o ro ${device_src}p2 "${tmpdir}"
      cp -af "${tmpdir}/." "${datadir}/"
      umount "${tmpdir}"
      rm -rf "${tmpdir}"
      losetup -d ${device_src}
    elif [[ "$filetype" =~ Squashfs ]]; then
      fn=$(basename ${arg})
      cp -f "${arg}" "${datadir}/apps/${fn}"
      chmod 0755 "${datadir}/apps/${fn}"
    fi
  elif [[ -d "${arg}" ]]; then
    cp -af "${arg}/." "${datadir}/"
  fi
done

set +e
# Zero fill disk buffers, to make better compression rates
cat /dev/zero >"${datadir}/zero.fill"
sync
sleep 1
sync
rm -f "${datadir}/zero.fill"
sync

umount "${datadir}"
rm -rf "${datadir}"
losetup -d ${device}

popd >/dev/null
