## Description
Reference and backup files. At start of setup, system files will backup (before overwritten by reference files). On script failure, system files will be restored.

## System files
* GRUB
    - */etc/default/grub*
    - */etc/grub.d/proxifiedScripts/custom*

* QEMU
    - */etc/apparmor.d/local/abstractions/libvirt-qemu*
    - */etc/libvirt/qemu.conf* <sup>[1](#1)</sup>

* Modules
    - */etc/initramfs-tools/modules*
    - */etc/modules*
    - */etc/modprobe.d/pci-blacklists.conf*
    - */etc/modprobe.d/vfio.conf*

## Notes
#### [2]
* **[source file (GitHub)](https://github.com/virtualopensystems/libvirt/blob/master/src/qemu/qemu.conf)**