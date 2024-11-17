## Booting ChromeOS Flex installed on nested GPT partition
### How to use this
> [!NOTE]
> This requies an existing ChromeOS Flex installation on the nested GPT partition, which is not covered in this README.
>
> WIP: Add steps for installing ChromeOS Flex on nested GPT

> [!NOTE]
> All required files are available on [Releases](https://github.com/supechicken/CrOS-Flex-NestedGPT/releases) page

- Copy `initramfs.img` and `kernel` into `<EFI partition>/ChromeOS`
- Extract `patches.tar.zst` into `/patches/` of the first partition (`STATE`) inside the nested GPT partition
- Add a new boot entry for booting the custom kernel/initramfs via EFISTUB:
```shell
BOOTARGS=(
  initrd=/ChromeOS/initramfs.img
  init=/sbin/init
  rootwait
  ro
  noresume
  kvm-intel.vmentry_l1d_flush=always
  i915.modeset=1
  cros_efi
  cros_debug
  iommu.passthrough=1
  lsm=landlock,lockdown,yama,loadpin,safesetid,integrity,selinux
)

sudo efibootmgr --create --disk <REPLACE WITH YOUR DRIVE> --part <REPLACE WITH YOUR EFI PARTITION> \
    --loader /ChromeOS/kernel \
    --label 'ChromeOS Flex (EFISTUB)' \
    --unicode "${BOOTARGS[*]}"
```

