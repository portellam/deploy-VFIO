## Description
Ultimate scripts for a seamless, intuitive, and automated VFIO passthrough setup. Run any OS with real hardware, under a virtual machine, in the Linux desktop of choice. 

Protect your desktop and files from untrusted hardware (webcam, microphone, etc.), software spyware/malware/abandonware (computer game Anti-cheat, Zoom, etc.), and OS (Windows 10/11 telemetry, Windows XP vulnerabilities). Seperate your workstation and gaming machine, from your personal computer.

## How-to
To install, execute:

        sudo bash install.sh

Post-install, execute:

        sudo bash post-install.sh

For best results post-installation, use **'portellam/AutoXorg'**:  https://github.com/portellam/Auto-Xorg

## What is VFIO?
* see hyperlink:        https://www.kernel.org/doc/html/latest/driver-api/vfio.html
* VFIO community:       https://old.reddit.com/r/VFIO
* a useful guide:       https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF

## Functions
* **Pre-install:**
    * **setup Hugepages**
        * Static allocation of Host RAM to VMs for zero memory fragmentation and reduced memory latencies (best to use whole Memory channels/sticks, if possible).
    * **setup Zram swapfile**
        * Compressed swapfile to RAM disk, to reduce occurrences of Host lock-up from over-allocated Host memory.
    * **static/dynamic CPU thread allocation:** **(work-in-progress)**
* **VFIO setup:**
    * Setup dynamically (Multi-Boot) or statically.
* **Post-install:**
    * **setup Evdev (Event devices)**
        * Virtual Keyboard-Mouse switch (better than nothing, best to have physical KVM and multiple PCI USB controllers).
        * Executes post-setup given assuming user passthroughs a USB controller (not necessary to parse all USB input devices).
    * **Libvirt-nosleep** system service to prevent Host sleep while virtual machine(s) are active (see credits in file)
    * **Auto VM Deployment** **(work-in-progress)**

* work-in-progress; more features to be added, as needed.

## VFIO setup *(expanded)*
* Parses list of PCI expansion devices (Bus IDs, Hardware IDs, and Kernel drivers), and 'IOMMU' groups of devices.
    * Saves lists of external PCI devices, by order of IOMMU groups.
* Prompt user for VFIO passthrough setup:
    * **Multi-Boot setup** **(work-in-progress: currently outputs only one valid boot entry, not all)**
        * Select a host VGA boot device at GRUB menu.
        * Appends to system file: **'/etc/grub.d/proxifiedScripts/custom'**
    * **Static setup**
        * Asks user to VFIO passthrough any IOMMU groups (with external PCI devices, including VGA devices).
        * Appends to system file(s): **'/etc/initramfs-tools/modules'**, **'/etc/modules'**, **'/etc/modprobe.d/*'**, **'/etc/default/grub'**.         
* Checks for existing VFIO setup, prompt user to uninstall setup, reboot, and try again to continue.

## DISCLAIMER
Tested on Debian Linux.

Please review your system's specifications and resources. Check BIOS/UEFI for Virtualization support (AMD IOMMU or Intel VT-d).