## Description
Backup files go here.

## System files
* GRUB
- */etc/default/grub*
- */etc/grub.d/proxifiedScripts/custom*

* QEMU
- */etc/apparmor.d/local/abstractions/libvirt-qemu* <sup>[1](#1)</sup>
- */etc/libvirt/qemu.conf* <sup>[2](#2)</sup>

* Modules
- */etc/initramfs-tools/modules*
- */etc/modules*
- */etc/modprobe.d/pci-blacklists.conf*
- */etc/modprobe.d/vfio.conf*

## Backup sources
#### [1]
* n/a

#### [2]
* ***[source file (GitHub)](https://github.com/virtualopensystems/libvirt/blob/master/src/qemu/qemu.conf)**
