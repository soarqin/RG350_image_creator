#!/usr/bin/env sh

set -e

if [ $# -eq 0 ]; then
  echo "Usage: $(basename $0) <update opk file>"
  exit 1
fi

pushd "$(dirname $0)" >/dev/null
source ./env.sh

device=$(losetup -Pf --show "${filename}")
mkdir -p "${bootdir}"
mkdir -p "$(dirname ${tmpdir})"
rm -rf "${tmpdir}"
unsquashfs -d "${tmpdir}" "$1"
mount -o noatime,nodiratime,rw ${device}p1 "${bootdir}"
for fn in modules.squashfs rootfs.squashfs vmlinuz.bin modules.squashfs.sha1 rootfs.squashfs.sha1 vmlinuz.bin.sha1; do
  if [[ -f "${tmpdir}/${fn}" ]]; then
    cp "${tmpdir}/${fn}" "${bootdir}/${fn}"
  fi
done

set +e
# Zero fill disk buffers, to make better compression rates
cat /dev/zero >"${bootdir}/zero.fill" 2>/dev/null
sync
sleep 1
sync
rm -f "${bootdir}/zero.fill"
sync

umount "${bootdir}"
rm -rf "${bootdir}" "${tmpdir}"
losetup -d ${device}

popd >/dev/null
