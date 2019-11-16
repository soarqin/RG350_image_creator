#!/usr/bin/env sh

pushd "$(dirname $0)" >/dev/null
source ./env.sh

size=$(((${part1_size}+${part2_size})*1024*2+32))

dd if=/dev/zero of="${filename}" oflag=append bs=512 count=${size}
(echo 32,819168,0xb
echo 819200,,0x83
echo write
) | sfdisk "${filename}"

dd bs=512 seek=1 if=./data/boot.bin of="${filename}" conv=notrunc
device=$(losetup -Pf --show "${filename}")
yes | mkfs.vfat -F32 ${device}p1
yes | mkfs.ext4 ${device}p2

mkdir -p "${bootdir}"
mount -o noatime,nodiratime,rw ${device}p1 "${bootdir}"
cp -Rf ./data/mininit-syspart*  "${bootdir}/"
mkdir -p "${bootdir}/dev" "${bootdir}/root"

umount "${bootdir}"
rm -rf "${bootdir}"
losetup -d ${device}

popd >/dev/null
