#!/bin/sh

/bin/umount /dev/mmcblk0p2 1>/dev/null 2>&1
let n=5
while [ `/bin/mount | grep mmcblk0p2 | wc -l` -gt 0 -a $n -gt 0 ]; do
  /bin/umount /dev/mmcblk0p2 1>/dev/null 2>&1
  echo "unmount failed, retrying ($n times left)"
  let n=$n-1
  sleep 1
done

(./pv -n __FILENAMEHOLDER__ | ./dd of=/dev/mmcblk0 oflag=sync bs=4M conv=notrunc,noerror) 2>&1 | dialog --gauge "Flashing, please wait..." 7 34 0
sync /dev/mmcblk0

dialog --msgbox '\n      Flash complete!\n\nThe system will now restart.\n\n' 8 0
reboot
