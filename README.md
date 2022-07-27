## To-Do
* Linux distro-agnostic setup
* Multi-boot VFIO setup:    output to GRUB menu entries (currently only logfiles for manual setup)
* Static VFIO setup:        fix driver parsing **make an array that saves WHICH IOMMU group is passedthru, and which isn't**
* post install setup:       auto generate virtual machine XML/templates [a VM for every config, including single omitted IOMMU groups (with VGA)], edits for OS-specific and BIOS/UEFI setups, include evdev and hugepages

## Complete
* Evdev setup
* Hugepages setup
* Zram-swap setup

## What is VFIO?
* see hyperlink:        https://www.kernel.org/doc/html/latest/driver-api/vfio.html
* VFIO community:       https://old.reddit.com/r/VFIO
* a useful guide:       https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF

## How-to
In terminal, execute:

        sudo bash install.sh

## Functions
* **setup Evdev (Event devices)**
    * Virtual Keyboard-Mouse switch (better than nothing, best to have physical KVM and multiple PCI USB controllers).
    * Restarts related system service.
* **setup Hugepages**
    * Static allocation of Host RAM to VMs for zero memory fragmentation and reduced memory latencies (best to use multiples of size of each Memory channel/stick).
* **setup Zram swapfile**
    * Compressed swapfile to RAM disk, to reduce occurrences of Host lock-up from over-allocated Host memory.
    * Restarts related system service.
* **VFIO setup.**
    * Setup dynamically (Multi-Boot) or statically.

## VFIO setup
* Parses list of PCI expansion devices (Bus IDs, Hardware IDs, and Kernel drivers), and 'IOMMU' groups of devices.
    * Saves lists of external PCI devices, by order of IOMMU groups.
* Prompt user for VFIO passthrough setup:
    * Dynamic/Multi-Boot setup **(RECOMMENDED)**
        * Adds multiple GRUB menu entries for all IOMMU groups with an external VGA device, minus a given VGA device's IOMMU group.
        * also executes Static setup.
    * Static setup
        * Asks user to VFIO passthrough any IOMMU groups (with external PCI devices, including VGA devices).
        * with Multi-boot setup: Asks user to VFIO passthrough any IOMMU groups (excluding external VGA devices).
        * Appends to **'/etc/initramfs-tools/modules'**, **'/etc/modules'**, **'/etc/modprobe.d/*'**.
        * Also appends to **'/etc/default/grub'**.         
* Updates GRUB and INITRAMFS.
* Checks for existing VFIO setup, asks user to uninstall setup and restart machine to continue, or exit.

## DISCLAIMER
**Work-in-progress**

Tested on Debian Linux.

Use script at your own risk!

Please refer to and review community guides for any help. Script is not guaranteed to work with all machines, including Laptop PCs, or machines with less-than-favorable IOMMU groups, etc.

Please review your system's specifications and resources. Check BIOS/UEFI for Virtualization support (AMD IOMMU or Intel VT-d).
