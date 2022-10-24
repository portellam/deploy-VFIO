## To-do
* refactor code
* BRANCH NOT FINISHED

## Description
Ultimate scripts to seamlessly deploy a VFIO setup (PCI passthrough). Multi-boot: Swap the preferred host graphics (VGA) device at GRUB boot menu. VFIO: Run any OS with real hardware, under a virtual machine (VM), in the Linux desktop of your choice.

## How-to
To execute:

        sudo bash deploy-vfio-setup.bash

OPTIONS:

        -h  --help       Display this prompt.
        -d  --delete     Delete existing VFIO setup.
        -f  --full       Execute pre-setup, prompt for either VFIO setup, and execute post-setup.
        -m  --multiboot  Execute or update Multiboot VFIO setup.
        -s  --static     Execute or update Static VFIO setup.

## What is VFIO?
* see hyperlink:        https://www.kernel.org/doc/html/latest/driver-api/vfio.html
* VFIO community:       https://old.reddit.com/r/VFIO
* a useful guide:       https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF

## Functions

* **Evdev (Event devices)** is a Virtual Keyboard-Video-Mouse switch (K.V.M w/o video). (good fall-back)
* **Hugepages**
    * Static allocation of system RAM to VMs for zero memory fragmentation and reduced memory latencies (best to use whole Memory channels/sticks, if possible).
        * Outputs to logfile, for future reference by Multi-boot updater.
* **Zram swapfile**
    * Compressed swapfile to RAM disk, to reduce occurrences of Host lock-up from over-allocated Host memory.
* **Static CPU isolation**
    * Static isolation of system CPU threads. **(see 'post-install/Libvirt hooks' for Dynamic isolation)**
    * Outputs to logfile, for future reference by VFIO setup.
* **Auto-Xorg** system service to find and set a valid host boot VGA device for Xorg. [1]
* Setup Multi-boot or static. Multi-boot: Swap the preferred host graphics (VGA) device at GRUB boot menu. **(see 'examples')**
* **update Multi-boot** with latest installed Linux kernels, and **select default boot entry.**
* **Loopback audio** user service, audio capture from VM to host (ex: PCI Line-out to on-board Line-in/Mic).
* IVSHMEM (Inter-VM Shared Memory Device):
    * **Evdev (Event devices)**
    * **Looking Glass** is a video capture of the VM GPU primary output, to host. [2]
    * **Scream** is audio capture (virtual audio cable) over virtual network bridge, from VM to host. [3]
* **Libvirt hooks** [4]
    * Invoke 'hooks' for individual VMs. **(w-i-p)** [4]
    * Switch display input (video output) at VM start. **(w-i-p)**
    * Prompt user to set/allocate system resources (CPU, memory) dynamically. **(w-i-p)**
    * **Libvirt-nosleep** system service to prevent Host sleep while VM(s) are active. **(works standalone)** [5]

* work-in-progress; more features to be added, as discovered and needed.

## VFIO setup *(expanded)*
* Parses list of PCI expansion devices (Bus IDs, Hardware IDs, and Kernel drivers), and 'IOMMU' groups of devices.
    * Saves lists of external PCI devices, by order of IOMMU groups.
* Prompt user for VFIO passthrough setup:
    * **Multi-boot**
        * bind passthrough devices to **vfio-pci** and **pci-stub** (example types: VGA and USB, respectively).
            * NOTE: 'lspci' may report a device is binded to its original driver.
                * For devices binded to 'pci-stub', this is normal.
                * For some child devices (VGA audio device) and/or devices that share drivers with onboard devices (onboard audio), this is normal.
        * Select a host VGA boot device at GRUB menu.   (**Auto-Xorg** [1] is recommended)
        * Creates up to three menu entries (for first three installed and latest Linux kernels), and **select default boot entry.**
        * Appends to GRUB: **'/etc/grub.d/proxifiedScripts/custom'**
        * Outputs to logfile, for future reference by updater.
    * **Static**
        * bind all passthrough devices to **vfio-pci** and **pci-stub** (GRUB), or **vfio-pci** only (system files).
        * Append to GRUB or system files:   **'/etc/default/grub'**, or **'/etc/initramfs-tools/modules'**, **'/etc/modules'**, and **'/etc/modprobe.d/*'**.
* Checks for existing VFIO setup, prompt user to uninstall setup, reboot, and try again to continue.

## Credits
**[1]:** https://github.com/portellam/Auto-Xorg

**[2]:** https://looking-glass.io/docs/B5.0.1/

**[3]:** https://github.com/duncanthrax/scream

**[4]:** modified, https://github.com/PassthroughPOST/VFIO-Tools

**[5]:** https://old.reddit.com/r/VFIO/comments/8ypedp/for_anyone_getting_issues_with_their_guest_when/ (ArchWiki, /u/sm-Fifteen)

## DISCLAIMER
**DO NOT CREATE/ADD NEW FILES, OF SAME NAME OR OTHERWISE, TO REPO DIRECTORY. MAY CAUSE CONFLICT WITH SCRIPT(S), AND UNINTENDED OPERATION OF, BUT NOT LIMITED TO, LOG FILE READ/WRITES.**

Tested on Debian Linux. Works on my machine!

Please review your system's specifications and resources. Check BIOS/UEFI for Virtualization support (AMD IOMMU or Intel VT-d).