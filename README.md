*If you like this script, please favorite and share. Thank you.*

## Description
Ultimate collection of scripts for a seamless, automated VFIO passthrough setup.

## How-to
To install, execute:    (to install functions individually, omit input variable **'y'**)

        sudo bash install.sh y

* Reboot successfully for changes to take effect.
Post-install, execute:  (for best results post-installation, use **'portellam/AutoXorg'**:  https://github.com/portellam/Auto-Xorg)

        sudo bash post-install.sh y

To uninstall, execute:

        sudo bash uninstall.sh y
* Reboot successfully for changes to take effect.

## What is VFIO?
* see hyperlink:        https://www.kernel.org/doc/html/latest/driver-api/vfio.html
* VFIO community:       https://old.reddit.com/r/VFIO
* a useful guide:       https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF

## Functions
* **setup Hugepages**
    * Static allocation of Host RAM to VMs for zero memory fragmentation and reduced memory latencies (best to use multiples of size of each Memory channel/stick).
* **setup Zram swapfile**
    * Compressed swapfile to RAM disk, to reduce occurrences of Host lock-up from over-allocated Host memory.
    * Restarts related system service.
* **VFIO setup**
    * Setup dynamically (Multi-Boot) or statically.
* **Post-install: setup Evdev (Event devices)**
    * Virtual Keyboard-Mouse switch (better than nothing, best to have physical KVM and multiple PCI USB controllers).
    * Restarts related system service.
    * Executes post-setup given assuming user passthroughs a USB controller (not necessary to parse all USB input devices).
* **Post-install: Auto VM Deployment** **(NOT AVAILABLE)**
    * Deploy auto-generated Virtual machines (for every config, include Evdev and Hugepages).

## VFIO setup *(expanded)*
* Parses list of PCI expansion devices (Bus IDs, Hardware IDs, and Kernel drivers), and 'IOMMU' groups of devices.
    * Saves lists of external PCI devices, by order of IOMMU groups.
* Prompt user for VFIO passthrough setup:
    * Dynamic/Multi-Boot setup **(SEE NOTES)**
        * Outputs multiple GRUB menu entries for each permutation of one absent, passedthrough IOMMU group (with a VGA device).
            * In other words, select a host VGA boot device at GRUB menu (use **'portellam/Auto-Xorg'** for best results).
        * **NOTE:** Currently outputs to logfile. Undetermined what system file to output to?
        * also executes Static setup.
    * Static setup
        * Asks user to VFIO passthrough any IOMMU groups (with external PCI devices, including VGA devices).
        * with Multi-boot setup: Asks user to VFIO passthrough any IOMMU groups (excluding external VGA devices).
        * Appends to system files: **'/etc/initramfs-tools/modules'**, **'/etc/modules'**, **'/etc/modprobe.d/*'**.
        * Also appends to system file: **'/etc/default/grub'**.         
* Updates GRUB and INITRAMFS.
* Checks for existing VFIO setup, asks user to uninstall setup and restart machine to continue, or exit.

## Complete
* VFIO Setup: Multi-boot: outputs to logfile, no system file
* VFIO Setup: Static Setup
* Evdev setup
* Hugepages setup
* Zram-swap setup

## To-Do
* **(Important)** VFIO Setup: Multi-boot:   locate system file (**'/etc/grub.d/40_custom'** ?)
* **(Optional)** Post-Install:              auto VM deployment
* **(Optional)** VFIO Setup:                Linux distro-agnostic setup: test!
* **(Optional)** VFIO Setup:                Uninstaller

## DISCLAIMER
Tested on Debian Linux.

Please review your system's specifications and resources. Check BIOS/UEFI for Virtualization support (AMD IOMMU or Intel VT-d).

Review logfiles for insight to complete your installation, should 'VFIO-Setup' or any components of 'VFIO-Setup' fail to complete installation.

I will try to answer any questions you may have here. Otherwise, please refer to community forums and guides for any help.