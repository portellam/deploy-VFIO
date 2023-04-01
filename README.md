## Status
work-in-progress

## Description
Effortlessly deploy a VFIO setup (PCI passthrough). Multi-boot: Select a VGA device for Host at GRUB boot menu. VFIO: Run any Guest OS with PCI hardware as a Virtual machine (VM), with your desktop OS untouched.

## Why?
* **Separation-of-Concerns**
    * Segregate your Work, Game, or School PC from your personal desktop computer.
* **Run a legacy OS** should your PCI hardware support it.
    * **VGA devices:** NVIDIA GTX 900-series, or AMD Radeon HD 7000-series (or before) (example: **Windows XP**).
    * **VGA devices:** NVIDIA 7000-series GTX (or before), or ATI (pre-AMD) (example: **Windows 98**).
    * **Audio devices:** Creative Soundblaster for that authentic, 1990s-2000s experience (example: **Windows 98**).
* **If it's greater control of your privacy you want**
    * Use **me_cleaner**. [9]

## What is VFIO?
* about:            https://www.kernel.org/doc/html/latest/driver-api/vfio.html
* VFIO community:   https://old.reddit.com/r/VFIO
* guide:            https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF

## How-to
#### To install, execute:

        sudo bash deploy-vfio.bash

### Usage
#### * Options that skip *all* user prompts.

        Usage:          bash deploy-vfio.bash [OPTION]... [ARGUMENTS]...
        Deploy a VFIO setup to a Linux machine that supports Para-virtualization and PCI Passthrough.

          --help        print this help and exit

#### Parse IOMMU

        Parse IOMMU groups and reference chosen database for the system's PCI devices.
        OPTIONS: *
          -f, --file            Reference file database.
          -i, --internal        Reference local database.
          -o, --online          Reference online database.

        ARGUMENTS: *
          all                   Select all IOMMU groups.
          no-vga                Select all IOMMU groups without VGA devices.
          [x-y,z]               Select specific IOMMU groups (comma separated, or ranges).

          Example:
            no-vga 14           Select group 14 and all non-VGA groups.
            1,14-16             Select groups 1, 14, 15, and 16.


#### Pre-setup

        Pre-setup OPTIONS: *
          -c, --cpu                     Allocate CPU.
          -e, --evdev                   Setup a virtual KVM switch.
          -h, --hugepages               Create static hugepages (pages greater than 4 KiB) to allocate RAM for guest(s).
          --uninstall-utils             Undo changes made by preliminary setup.

        Hugepages ARGUMENTS: *
          2M, 1G                        Hugepage size (2 MiB or 1 GiB).
          [1-?]                         Amount of Hugepages (maximum amount is total memory subtracted by 4 GiB).

          Example:
            1G 16                       1 GiB hugepage * 16     == 16 GiB allocated to hugepages.
            2M 8192                     2 MiB hugepage * 8912   == 16 GiB allocated to hugepages.

#### Main-setup

        Main setup OPTIONS: *
          -m, --multiboot               Create multiple GRUB entries for a Multi VGA VFIO setup.
          -s, --static                  Install a Single VGA VFIO setup.
          -u, --uninstall               Undo an existing VFIO setup.

          Example:
            -l -m                       Parse against local database, then deploy a Multi VGA VFIO setup.
            -s -o -p                    Setup hugepages, parse against online database, then deploy a Static VFIO setup.

#### Post-setup

        Post-setup OPTIONS:
          -H, --hooks           Install recommended libvirt-hooks and services.
          -l, --looking-glass   Install LookingGlass.                   Stream video (and audio) from guest to host over PCI bus using shared-memory device.
          -L, --audio-loopback  Install the audio loopback service.     Loopback audio from guest to host (over Line-out to Line-in). *
          -S, --scream          Install Scream.                         Stream audio from guest to host over virtual LAN.
          -x  --auto-xorg       Install auto-Xorg.                      System service to find and set a valid Host boot VGA device for Xorg.
          -z, --zram-swap       Create compressed (~ 2:1) RAM swap.     Reduce chances of memory exhaustion for host.
          --uninstall-extras    Undo changes made by post-setup. *

        zram-swap ARGUMENTS:
          [fraction]            Set the fraction of total available memory.
          force                 Force changes, even if zram-swap is allocated and in use. *

          Example (assume a host with 32 GiB of RAM):
            1/4 force           Force changes and compress 8 GiB of RAM, to create 16 GiB of swap, with 16 GiB free.
            1/8                 Compress 4 GiB of RAM, to create 8 GiB of swap, with 28 GiB free.

#### * Options that skip *all* user prompts.

## Features
### Pre-setup  (vfiolib-utils)
* **Allocate CPU**
    * Reduce Host overhead, and improve both Host and Guest performance.
    * **Statically** allocate Host CPU cores (and/or threads). [2]
* **Allocate RAM**
    * Eliminate the need to defragment Host memory (RAM) before allocating Guest memory.
    * Reduce Host overhead, and improve both Host and Guest performance.
    * **Statically** allocate Host memory to Guests.
    * Implementation is known as **Hugepages**. [3]
* **Virtual KVM (Keyboard Video Mouse) switch**
    * Allow a user to swap a group of Input devices (as a whole) between active Guest(s) and Host.
    * Use the pre-defined macro (example: **'L-CTRL' + 'R-CTRL'**).
    * Create a virtual Keyboard-Video-Mouse switch.
    * Implementation is known as **Evdev (Event Devices)**. [6]
    * **Disclaimer:** Guest PCI USB is good. Both implementations together is better.

### Main VFIO setup (vfiolib-main)
* **Multi-boot VFIO setup**
    * Best for Multiple VGA PCI Passthrough (**one** VGA for Host, and **multiple** VGA for Guests).    **More flexibility.**
    * Multiple GRUB menu entries for multiple VGA device systems. Choose a GRUB menu entry with a VGA device to boot from (exclude that VGA device's IOMMU Group from PCI Passthrough/VFIO).
    * **Disclaimer:** For best results, use **Auto-Xorg**. [1]
* **Static VFIO setup**
    * Best for Single VGA PCI Passthrough (**one** VGA for Host, and **one** VGA for Guests).           **Less flexibility.**
    * Traditional PCI Passthrough/VFIO setup.

### Post-setup  (vfiolib-extras)
* **Auto-Xorg** system service to find and set a valid Host boot VGA (GPU) device for Xorg. [1]
* **Guest Audio Capture**
    * Useful for systems with multiple Audio devices.
    * Create an **Audio loopback** to output on the **Host's** Audio device **Line-Out**.
    * Listen on **Host** Audio device **Line-In** (from **Guest** PCI Audio device **Line-Out**).
    * For virtual implementation, see **Virtual Audio Capture**.
* **Libvirt Hooks**
    * Invoke **"hooks"** (scripts) for individual Guests. [4]
    * Switch display input (video output) at Guest start.
    * **Dynamically** allocate system resources (CPU, RAM).
    * **Libvirt-nosleep** system service(s) per Guest to prevent Host sleep while Guest is active.
* **RAM as Compressed Swapfile/partition**
    * Reduce swapiness to existing Host swap devices, and reduce chances of Host memory exhaustion (given an event of memory over-allocation).
    * Create a compressed Swap device in Host memory, using the **lz4** algorithm **(compression ratio of about 2:1)**.
    * Implementation is known as **zram-swap**. [5]
* **Virtual Audio Capture**
    * Setup a virtual Audio driver for Windows that provides a discrete Audio device.
    * Implementation is known as **Scream**. [7]
* **Virtual Video Capture**
    * Setup direct-memory-access (DMA) of a PCI VGA device output (Video and Audio) from a Guest to Host.
    * Implementation is known as **LookingGlass**. [8]
    * **Disclaimer:** Only supported for Windows 7/8/10/11 Guests.

## References
### [1]
* **Auto-Xorg:**    https://github.com/portellam/Auto-Xorg

### [2]
* **isolcpu:**  https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF#CPU_pinning

### [3]
* **Hugepages:**    https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF#Huge_memory_pages

### [4]
* https://github.com/PassthroughPOST/VFIO-Tools
* **libvirt-nosleep:**    https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF#Host_lockup_if_guest_is_left_running_during_sleep

### [5]
* **zram-swap:**    https://github.com/foundObjects/zram-swap
* **Debian:**       https://wiki.debian.org/ZRam
* **Arch:**         https://aur.archlinux.org/packages/zramswap
* **about lz4:**    https://github.com/lz4/lz4
* **benchmarks:**   https://web.archive.org/web/20220201101923/https://old.reddit.com/r/Fedora/comments/mzun99/new_zram_tuning_benchmarks/

### [6]
* **Evdev:**    https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF#Passing_keyboard/mouse_via_Evdev

### [7]
* **Scream:**   https://github.com/duncanthrax/scream

### [8]
* **LookingGlass:** https://looking-glass.io/docs/B5.0.1/

### [9]
* **original:**     https://github.com/corna/me_cleaner
* **updated fork:** https://github.com/dt-zero/me_cleaner

## Disclaimers
Use at your own risk.
Please review your system's specifications and resources. Check BIOS/UEFI for Virtualization support (AMD IOMMU or Intel VT-d).

## Contribution
Should you find this script useful, please reach out via the **Issues** tab on GitHub. Thank you.