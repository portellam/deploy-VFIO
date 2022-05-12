# Status: Work-in-progress
#
## What is VFIO?
* See hyperlink:  https://www.kernel.org/doc/html/latest/driver-api/vfio.html
* Useful guide:   https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF
* Community:      https://old.reddit.com/r/VFIO
#
## How-to
###### In terminal, execute:

        sudo bash Auto-VFIO.sh $1 $2 $3 $4 $5 $6
###### Multi-Boot setup or Static setup:
        $1 == "Y/N" or "B/S"
###### enable EvDev:
        $2 == "Y/N" or "E/N"
###### enable ZRAM:
        $3 == "Y/N" or "Z/N"
###### enable Hugepages, set size, set sum:
        $4 == "Y/N" or "H/N"
        $5 == "2M/1G"
        $6 == integer
#
## Auto-VFIO
Automate VFIO passthrough setup, dynamically ('Multi-Boot') or statically.
* Runs once at boot.
* Parses list of PCI expansion devices (Bus IDs, Hardware IDs, and Kernel drivers)
* Prompt user for VFIO passthrough setup:
    * Dynamic/Multi-Boot    **(RECOMMENDED)**
        * adds multiple GRUB menu entries for each non-passthrough VGA device, and one entry with every VGA device passed-through). 
    * Static
        * appends to '/etc/initramfs-tools/modules', '/etc/modules', '/etc/modprobe.d/*' 
* Hugepages
    * static allocation of RAM for zero memory fragmentation and reduced memory latency. Best-case scenario: use whole Memory channels/sticks.
* Event devices (Evdev)
    * virtual Keyboard-Mouse switch (best to have physical KVM and multiple PCI USB devices, better than nothing).
* Zram swapfile
    * compressed swapfile to RAM disk, to reduce Host lock-up from over-allocated Host memory.
#
