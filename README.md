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
    * Parses list of PCI expansion devices (Bus IDs, Hardware IDs, and Kernel drivers), and 'IOMMU' groups (see **guide** above) of devices.
        * Saves lists of external PCI devices, by order of IOMMU groups.
    * Prompt user for VFIO passthrough setup:
        * Dynamic/Multi-Boot    **(RECOMMENDED)**
            * Adds multiple GRUB menu entries for all IOMMU groups with an external VGA device, minus a given VGA's IOMMU group.
            * Executes Static setup.
        * Static
            * Asks user to VFIO passthrough any IOMMU groups (with external PCI devices including VGA devices).
                * with Multi-boot setup: Asks user to VFIO passthrough any IOMMU groups (excluding external VGA devices).
            * Appends to "/etc/initramfs-tools/modules", "/etc/modules", " /etc/modprobe.d/* ".
                * Also appends to "/etc/default/grub".         
    * Updates GRUB and INITRAMFS .
* Automatic features:
    * Checks for existing VFIO setup, asks user to uninstall setup and restart machine to Continue.
