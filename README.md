## Description
Effortlessly deploy a VFIO setup (PCI passthrough). Multi-boot: Select a video card for Host at GRUB boot menu. VFIO: Run any Virtual machine with real hardware, separate from your desktop host machine.

## Status: partial completion (see TODO.md)

## Why?
* **Separation-of-Concerns**
    - Segregate your Work, Game, or School PC from your personal desktop computer.
* **Run a legacy OS** should your PCI hardware support it.
    - **VGA devices:** NVIDIA GTX 900-series, or AMD Radeon HD 7000-series (or before) (example: **Windows XP**).
    - **VGA devices:** NVIDIA 7000-series GTX (or before), or ATI (pre-AMD) (example: **Windows 98**).
    - **Audio devices:** Creative Soundblaster for that authentic, 1990s-2000s experience (example: **Windows 98**).
* **If it's greater control of your privacy you want**
    - Use **me_cleaner**.<sup>[1](#1)</sup>

## What is VFIO?
* about:            https://www.kernel.org/doc/html/latest/driver-api/vfio.html
* VFIO community:   https://old.reddit.com/r/VFIO
* guide:            https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF

## How-to
#### To install, execute:

        sudo bash installer.bash

### Usage
#### * Options that skip *all* user prompts.

        Usage:          sudo bash deploy-vfio [OPTION]... [ARGUMENTS]...
        Deploy a VFIO setup to a Linux Host machine that supports Para-virtualization (PCI Passthrough).

          --help        Print this help and exit.

#### Parse IOMMU

        Parse IOMMU groups and reference chosen database for the system's PCI devices.
        OPTIONS: *
          -f, --file [filename] Reference file database.
          -i, --internal        Reference local database.
          -o, --online          Reference online database.

        ARGUMENTS: *
          [filename]            Reference specific file.
          all                   Select all IOMMU groups.
          no-vga                Select all IOMMU groups without VGA devices.
          [x-y,z]               Select specific IOMMU groups (comma separated, or ranges).

          Example:
            -f somefile.txt     Reference file 'somefile.txt' and begin parse.
            no-vga 14           Select group 14 and all non-VGA groups.
            1,14-16             Select groups 1, 14, 15, and 16.


#### Pre-setup

        Pre-setup OPTIONS: *
          -c, --cpu                     Allocate CPU.
          -e, --evdev                   Setup a virtual KVM switch.
          -h, --hugepages               Create static hugepages (pages greater than 4 KiB) to allocate RAM for Guest(s).
          --uninstall-essentials             Undo changes made by preliminary setup.

        Hugepages ARGUMENTS: *
          2M, 1G                        Hugepage size (2 MiB or 1 GiB).
          [1-?]                         Amount of Hugepages (maximum amount is total memory subtracted by 4 GiB).

          Example:
            1G 16                       1 GiB hugepage * 16     == 16 GiB allocated to hugepages.
            2M 8192                     2 MiB hugepage * 8912   == 16 GiB allocated to hugepages.

#### Main setup

        Main setup OPTIONS: *
          -m, --multiboot               Create multiple GRUB entries for a Multi VGA VFIO setup.
          -s, --static                  Install a Single VGA VFIO setup.
          -u, --uninstall               Undo an existing VFIO setup.

          Example:
            -l -m                       Parse against local database, then deploy a Multi VGA VFIO setup.
            -s -o                       Parse against online database, then deploy a Static VFIO setup.

#### Post-setup

        Post-setup OPTIONS:
          -H, --hooks           Install recommended Libvirt hooks and services.
          -L, --audio-loopback  Install the audio loopback service.     Loopback audio from Guest to Host (over Line-out to Line-in). *
          -z, --zram-swap       Create compressed (~ 2:1) RAM swap.     Reduce chances of memory exhaustion for Host.
          --uninstall-extras    Undo changes made by post-setup. *

        zram-swap ARGUMENTS:
          [fraction]            Set the fraction of total available memory.
          force                 Force changes, even if zram-swap is allocated and in use. *

          Example (assume a Host with 32 GiB of RAM):
            1/4 force           Force changes and compress 8 GiB of RAM, to create 16 GiB of swap, with 16 GiB free.
            1/8                 Compress 4 GiB of RAM, to create 8 GiB of swap, with 28 GiB free.

#### * Options that skip *all* user prompts.

## Features
### Pre-setup  <sub>(vfiolib-essentials)</sub>
* **Allocate CPU**
    - Reduce Host overhead, and improve both Host and Guest performance.
    - **Statically** allocate of Host CPU cores (and/or threads).<sup>[2](#2)</sup>
    - **Dynamically** allocate as a **Libvirt hook**.
* **Allocate RAM**
    - Eliminate the need to defragment Host memory (RAM) before allocating Guest memory.
    - Reduce Host overhead, and improve both Host and Guest performance.
    - **Statically** allocate Host memory to Guests.
    - Implementation is known as **Hugepages**.<sup>[3](#3)</sup>
* **Virtual KVM (Keyboard Video Mouse) switch**
    - Allow a user to swap a group of Input devices (as a whole) between active Guest(s) and Host.
    - Use the pre-defined macro (example: **'L-CTRL' + 'R-CTRL'**).
    - Create a virtual Keyboard-Video-Mouse switch.
    - Implementation is known as **Evdev (Event Devices)**.<sup>[4](#4)</sup>
    - **Disclaimer:** Guest PCI USB is good. Both implementations together is better.

### Main setup <sub>(vfiolib-setup)</sub>
* **Multi-boot VFIO setup**
    - Multiple VGA PCI Passthrough.
    - Multiple GRUB menu entries.
    - Best for systems with two or more PCI VGA devices.                      **More flexibility.**
    - Choose a GRUB menu entry with a VGA device to boot from (excludes that VGA device's IOMMU group from VFIO).
    - **Disclaimer:** For best results, use **auto-Xorg**.<sup>[5](#5)</sup>
* **Static VFIO setup**
    - Single VGA PCI Passthrough.
    - Best for systems with integrated VGA device and one PCI VGA device.     **Less flexibility.**
    - Traditional PCI Passthrough/VFIO setup.
    - Choose method of setup:
        - GRUB
        - system configuration files

### Post-setup  <sub>(vfiolib-extras)</sub>
* **Guest Audio Capture**
    - Useful for systems with multiple Audio devices.
    - Create an **Audio loopback** to output on the **Host's** Audio device **Line-Out**.
    - Listen on **Host** Audio device **Line-In** (from **Guest** PCI Audio device **Line-Out**).
    - For virtual implementation, see **Virtual Audio Capture**.
* **Libvirt Hooks**
    - Invoke **"hooks"** (scripts) for all or individual Guests.<sup>[6](#6)</sup>
    - Switch display input (video output) at Guest start.
    - **Dynamically** allocate CPU cores and CPU scheduler.
    - **Libvirt-nosleep** system service(s) per Guest to prevent Host sleep while Guest is active.
* **RAM as Compressed Swapfile/partition**
    - Reduce swapiness to existing Host swap devices, and reduce chances of Host memory exhaustion (given an event of memory over-allocation).
    - Create a compressed Swap device in Host memory, using the **lz4** algorithm **(compression ratio of about 2:1)**.
    - Implementation is known as **zram-swap**.<sup>[7](#7)</sup>

## References
#### [1]
- <sub>**[me_cleaner, original (GitHub)](https://github.com/corna/me_cleaner)**</sub>
- <sub>**[me_cleaner, updated (GitHub)](https://github.com/dt-zero/me_cleaner)**</sub>

#### [2]
- <sub>**[isolcpu (Arch wiki)](https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF#CPU_pinning)**</sub>

#### [3]
- <sub>**[Hugepages (Arch wiki)](https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF#Huge_memory_pages)**</sub>

#### [4]
- <sub>**[Evdev (Arch wiki)](https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF#Passing_keyboard/mouse_via_Evdev)**</sub>

#### [5]
- <sub>**[auto-Xorg (GitHub)](https://github.com/portellam/auto-Xorg)**</sub>

#### [6]
- <sub>**[VFIO-Tools (GitHub)](https://github.com/PassthroughPOST/VFIO-Tools)**</sub>
- <sub>**[libvirt-nosleep (Arch wiki)](https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF#Host_lockup_if_Guest_is_left_running_during_sleep)**</sub>

#### [7]
- <sub>**[zram-swap (GitHub)](https://github.com/foundObjects/zram-swap)**</sub>
- <sub>**[lz4 (GitHub)](https://github.com/lz4/lz4)**</sub>
- <sub>**[zram package (Debian)](https://wiki.debian.org/ZRam)**</sub>
- <sub>**[zram package (Arch)](https://aur.archlinux.org/packages/zramswap)**</sub>
- <sub>**[zram benchmarks (Reddit)](https://web.archive.org/web/20220201101923/https://old.reddit.com/r/Fedora/comments/mzun99/new_zram_tuning_benchmarks/)**</sub>

#### [8]
- <sub>**[Scream (GitHub)](https://github.com/duncanthrax/scream)**</sub>

#### [9]
- <sub>**[LookingGlass (website)](https://looking-glass.io/docs/B5.0.1/)**</sub>

## Disclaimer
Use at your own risk.
Please review your system's specifications and resources. Check BIOS/UEFI for Virtualization support (AMD IOMMU or Intel VT-d).