## Work-In-Progress

## What is VFIO?
* see hyperlink:        https://www.kernel.org/doc/html/latest/driver-api/vfio.html
* VFIO community:       https://old.reddit.com/r/VFIO
* a useful guide:       https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF

## How-to
In terminal, execute:

        sudo bash Auto-VFIO.sh
        
## Auto-VFIO
Automated VFIO passthrough setup. Setup dynamically (Multi-Boot) or statically.
* Runs once at boot.
* Recommended features:
    * Evdev (Event devices)
        * Virtual Keyboard-Mouse switch (best to have physical KVM and multiple PCI USB devices, better than nothing).
        * Restarts related system service.
    * Hugepages
        * Static allocation of RAM for zero memory fragmentation and reduced memory latency (best to use multiples of each Memory channel/stick).
    * Zram swapfile
        * Compressed swapfile to RAM disk, to reduce occurrences of Host lock-up from over-allocated Host memory.
        * Restarts related system service.
* Main features:
    * Parses list of PCI expansion devices (Bus IDs, Hardware IDs, and Kernel drivers).
        * Checks IOMMU groups/PCI groups of PCI devices, for conflicts. Adjusts accordingly.
    * Prompt user for VFIO passthrough setup:
        * Dynamic/Multi-Boot    **(RECOMMENDED)**       + Static-Setup
            * Parses 'IOMMU' groups (see **guide** above), lists all PCI devices that reside in given IOMMU group.
            * Adds multiple GRUB menu entries for each non-passthrough VGA device (and given IOMMU group), and one entry with every VGA device passed-through).
            * Executes 'Static' setup for non-VGA devices and different IOMMU groups.
        * Static
            * if Multi-Boot setup was ran, warns user of any VGA device in given IOMMU group
            * Appends to "/etc/initramfs-tools/modules", "/etc/modules", " /etc/modprobe.d/* ".
                * Also appends to "/etc/default/grub" (no Multi-Boot).
    * Updates GRUB and INITRAMFS .
* Automatic features:
    * Checks for existing VFIO setup, asks user to uninstall setup and restart machine to Continue.
