*If you like this script, please favorite and share. Thank you.*

## Description
Ultimate collection of scripts for an Automated VFIO passthrough setup:
* Setup Multi-Boot or static VFIO passthrough, Evdev, Hugepages, ZRAM swap.
* Deploy auto-generated Virtual machines.

## How-to
In terminal, execute:

        sudo bash install.sh

## What is VFIO?
* see hyperlink:        https://www.kernel.org/doc/html/latest/driver-api/vfio.html
* VFIO community:       https://old.reddit.com/r/VFIO
* a useful guide:       https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF

## Functions
* **setup Evdev (Event devices)**
    * Virtual Keyboard-Mouse switch (better than nothing, best to have physical KVM and multiple PCI USB controllers).
    * Restarts related system service.
* **setup Hugepages**
    * Static allocation of Host RAM to VMs for zero memory fragmentation and reduced memory latencies (best to use multiples of size of each Memory channel/stick).
* **setup Zram swapfile**
    * Compressed swapfile to RAM disk, to reduce occurrences of Host lock-up from over-allocated Host memory.
    * Restarts related system service.
* **VFIO setup**
    * Setup dynamically (Multi-Boot) or statically.
* **Post-install**
    * Deploy auto-generated Virtual machines (for every config, include Evdev and Hugepages).

## VFIO setup *(expanded)*
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

## To-Do
* Linux distro-agnostic setup
* Multi-boot VFIO setup:    output to GRUB menu entries automaticcaly (currently only outputs logfiles)
* Static VFIO setup:        fix driver parsing => **make an array that saves which IOMMU group is passedthru, and which isn't**
* post install setup

## Complete
* Evdev setup
* Hugepages setup
* Zram-swap setup

## DISCLAIMER
**Work-in-progress**

Tested on Debian Linux.

Please review your system's specifications and resources. Check BIOS/UEFI for Virtualization support (AMD IOMMU or Intel VT-d).

**VFIO Setup** is not guaranteed to work with all machines, including Laptop PCs, or machines with less-than-favorable IOMMU groups, etc.
Review logfiles for insight to complete your setup.

I will try to answer any questions you may have here. Otherwise, please refer to community forums and guides for any help.