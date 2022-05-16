# WORK-IN-PROGRESS
## What is VFIO?
* See hyperlink:  https://www.kernel.org/doc/html/latest/driver-api/vfio.html

#
## How-to
In terminal, execute:

        sudo bash Auto-VFIO.sh
#
## Auto-VFIO
Automated VFIO passthrough setup. Setup dynamically (Multi-Boot) or statically.
* Runs once at boot.
* Recommended features:
    * Evdev (Event devices)
        * virtual Keyboard-Mouse switch (best to have physical KVM and multiple PCI USB devices, better than nothing).
    * Hugepages
        * static allocation of RAM for zero memory fragmentation and reduced memory latency (best to use multiples of each Memory channel/stick).
    * Zram swapfile
        * compressed swapfile to RAM disk, to reduce occurrences of Host lock-up from over-allocated Host memory.
* Main feature:
    * Parses list of PCI expansion devices (Bus IDs, Hardware IDs, and Kernel drivers)
    * Prompt user for VFIO passthrough setup:
        * Dynamic/Multi-Boot    **(RECOMMENDED)**
            * adds multiple GRUB menu entries for each non-passthrough VGA device, and one entry with every VGA device passed-through).
        * Static
            * appends to '/etc/initramfs-tools/modules', '/etc/modules', '/etc/modprobe.d/*'.
