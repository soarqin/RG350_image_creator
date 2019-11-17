#!/usr/bin/env sh

set -e

if [ $# -eq 0 ]; then
  echo "Usage: $(basename $0) <img file>"
  exit 1
fi

pushd "$(dirname $0)" >/dev/null

DATE=`date -r "$1" +%F`

mkdir -p output
cat > output/default.gcw0.desktop <<EOF
[Desktop Entry]
Name=MMC Flasher
Comment=OpenDingux MMC Flasher $DATE
Exec=flasher.sh
Icon=opendingux
Terminal=true
Type=Application
StartupNotify=true
Categories=applications;
EOF

sed -e "s|__FILENAMEHOLDER__|./$(basename "$1")|g" src/flasher.sh > output/flasher.sh
chmod +x output/flasher.sh

echo "$DATE" > output/date.txt

OPK_FILE=output/rg350-flasher-$DATE.opk
mksquashfs output/default.gcw0.desktop src/opendingux.png output/flasher.sh src/pv src/dd output/date.txt \
    "$1" $OPK_FILE -no-progress -noappend -comp gzip -all-root

popd >/dev/null
