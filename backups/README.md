## Description
Backup files go here.

## System files
* GRUB
- */etc/default/grub*<sup>[1](#1)</sup>
- */etc/grub.d/proxifiedScripts/custom*

* QEMU
- */etc/apparmor.d/local/abstractions/libvirt-qemu*<sup>[2](#2)</sup>
- */etc/libvirt/qemu.conf*<sup>[3](#3)</sup>

* Modules
- */etc/initramfs-tools/modules*
- */etc/modules*
- */etc/modprobe.d/pci-blacklists.conf*
- */etc/modprobe.d/vfio.conf*

## Backup sources
#### [1]
- <sub>*/usr/share/grub/default/grub*</sub>

#### [2]
- <sub>n/a</sub>

#### [3]
- <sub>**[source file (GitHub)](https://github.com/virtualopensystems/libvirt/blob/master/src/qemu/qemu.conf)**</sub>
