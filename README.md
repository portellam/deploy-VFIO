## To-Do
* Multi-boot VFIO setup
* Static-boot VFIO setup
* fix dependency for Hugepages logfile, ignore and continue without it for users who choose not to use it.
* create logfiles for manual setup?

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
    * Virtual Keyboard-Mouse switch (better than nothing, best to have physical KVM and multiple PCI USB devices).
    * Restarts related system service.
* **setup Hugepages**
    * Static allocation of RAM for zero memory fragmentation and reduced memory latency (best to use multiples of each Memory channel/stick).
* **setup Zram swapfile**                                                              *(depends on logfile from 'Hugepages' setup)*
    * Compressed swapfile to RAM disk, to reduce occurrences of Host lock-up from over-allocated Host memory.
    * Restarts related system service.
* **VFIO setup.**
    * Setup dynamically (Multi-Boot) or statically.

## VFIO setup
* Parses list of PCI expansion devices (Bus IDs, Hardware IDs, and Kernel drivers), and 'IOMMU' groups (see **guide** above) of devices.
    * Saves lists of external PCI devices, by order of IOMMU groups.
* Prompt user for VFIO passthrough setup:
    * Dynamic/Multi-Boot setup **(RECOMMENDED)**
        * Adds multiple GRUB menu entries for all IOMMU groups with an external VGA device, minus a given VGA's IOMMU group.
        * Executes Static setup.
    * Static setup
        * Asks user to VFIO passthrough any IOMMU groups (with external PCI devices including VGA devices).
        * with Multi-boot setup: Asks user to VFIO passthrough any IOMMU groups (excluding external VGA devices).
        * Appends to "/etc/initramfs-tools/modules", "/etc/modules", " /etc/modprobe.d/* ".
        * Also appends to "/etc/default/grub".         
* Updates GRUB and INITRAMFS.
* Checks for existing VFIO setup, asks user to uninstall setup and restart machine to Continue.

## DISCLAIMER
**Work-in-progress**

Use script at your own risk!

Please refer and review community guides for any help. Script is not guaranteed to work with Laptop machines, host machines with less-than-favorable IOMMU groups, etc.

Please review host machine's system specifications and resources. Check your system's BIOS/UEFI for Virtualization support (AMD IOMMU or Intel VT-d).
