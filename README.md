## Description
Ultimate scripts for a seamless and automated VFIO (PCI passthrough) setup. Run any OS with real hardware, under a virtual machine, in the Linux desktop of your choice.

## How-to
To install, execute:

        sudo bash install.bash

Post-install, execute:

        sudo bash post-install.bash

## What is VFIO?
* see hyperlink:        https://www.kernel.org/doc/html/latest/driver-api/vfio.html
* VFIO community:       https://old.reddit.com/r/VFIO
* a useful guide:       https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF

## Functions
* **Pre-install:**
    * **Hugepages**
        * Static allocation of Host RAM to VMs for zero memory fragmentation and reduced memory latencies (best to use whole Memory channels/sticks, if possible).
    * **Zram swapfile**
        * Compressed swapfile to RAM disk, to reduce occurrences of Host lock-up from over-allocated Host memory.
    * **static/dynamic CPU thread allocation** (work-in-progress)
    * **Auto-Xorg** system service to find and set a valid host boot VGA device for Xorg. [1]
* **VFIO setup:**
    * Setup dynamically (Multi-Boot) or statically.
* **Post-install:**
    * **update Multi-Boot** with latest Linux kernel.
    * **Evdev (Event devices)**
        * Virtual Keyboard-Mouse (KVM) switch (good fall-back, better to have physical KVM, multiple PCI USBs).
        * Parses all non-VFIO input devices.
    * **Libvirt hooks** include
        * Switch display input (video output) at VM start. [2]
        * Prompt user to set/allocate system resources (CPU, memory) dynamically. (work-in-progress) [2] 
        * **Libvirt-nosleep** system service to prevent Host sleep while virtual machine(s) are active. [3]
    * **Auto VM Deployment** (work-in-progress)

* work-in-progress; more features to be added, as discovered and needed.

## VFIO setup *(expanded)*
* Parses list of PCI expansion devices (Bus IDs, Hardware IDs, and Kernel drivers), and 'IOMMU' groups of devices.
    * Saves lists of external PCI devices, by order of IOMMU groups.
* Prompt user for VFIO passthrough setup:
    * **Multi-Boot** (disclaimer: currently outputs only one valid boot entry, not all)
        * Select a host VGA boot device at GRUB menu.   (**Auto-Xorg** is recommended)
        * Appends to system file: **'/etc/grub.d/proxifiedScripts/custom'**
    * **Static**
        * Asks user to VFIO passthrough any IOMMU groups (with external PCI devices, including VGA devices).
        * Appends to system file(s): **'/etc/initramfs-tools/modules'**, **'/etc/modules'**, **'/etc/modprobe.d/*'**, **'/etc/default/grub'**.         
* Checks for existing VFIO setup, prompt user to uninstall setup, reboot, and try again to continue.

## Credits
**[1]:** (https://github.com/portellam/Auto-Xorg)

**[2]:** modifications of (https://github.com/PassthroughPOST/VFIO-Tools)

**[3]:** /u/sm-Fifteen (https://old.reddit.com/r/VFIO/comments/8ypedp/for_anyone_getting_issues_with_their_guest_when/), ArchWiki

## DISCLAIMER
Tested on Debian Linux. Works on my machine!

Please review your system's specifications and resources. Check BIOS/UEFI for Virtualization support (AMD IOMMU or Intel VT-d).