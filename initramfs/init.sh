#!/bin/sh -eu

ROOTDEV=/dev/vda3

# setup mounts
mount -t proc proc /proc
mount -t sysfs sysfs /sys
mount -t devtmpfs devtmpfs /dev

# map nested GPT partition
losetup --direct-io=off -P /dev/vda /dev/sda2

if [ "$(cgpt show -i 4 -P /dev/vda)" -ge "$(cgpt show -i 2 -P /dev/vda)" ]; then
  # use ROOT-B
  ROOTDEV=/dev/vda5
  echo 'initramfs: will boot ROOT-B' > /dev/kmsg
else
  echo 'initramfs: will boot ROOT-A' > /dev/kmsg
fi

# mount rootfs
mount -t ext4 -o ro "${ROOTDEV}" /root

if [ ! -f /root/.rootfs_patched ]; then
  echo 'initramfs: patching rootfs...' > /dev/kmsg

  # enable rw
  echo -en '\000' | dd of="${ROOTDEV}" seek=1127 count=1 bs=1 conv=notrunc

  # remount as rw
  mount -o remount,sync,rw /root

  # mount stateful partition
  mount -t ext4 -o ro /dev/vda1 /mnt

  # update kernel modules and firmware
  rm -rf /root/lib/modules/* /root/lib/firmware
  tar -xf /mnt/patches/modules.tar.zst -C /root
  tar -xf /mnt/patches/firmware.tar.zst -C /root

  # LD_PRELOAD hack for sudo
  tar -xf /mnt/patches/minijail-hack.tar.zst -C /root
  sed -i '1s,^,env LD_PRELOAD=/usr/lib64/minijail-hack.so\n,' /root/etc/init/ui.conf

  # finishing touches
  date -R > /root/.rootfs_patched

  # remount as ro
  mount -o remount,async,ro /root

  # umount stateful partition
  umount /mnt
fi

# switch to ChromeOS
exec switch_root /root /sbin/init "${@}"
