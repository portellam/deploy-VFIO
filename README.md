# deploy-VFIO
## Contents
* [About](#About)
* [How-to](#How-to)
* [Features](#Features)
* [Information](#Information)
* [References](#References)
* [Disclaimer](#Disclaimer)

## About
### Description:
Effortlessly deploy a hardware passthrough (VFIO) setup, to run Virtual machines, on your Linux computer. Includes many common-sense quality-of-life enhancements.

### Status: Functional and [Developing](https://github.com/portellam/deploy-vfio/tree/develop) (see [TODO.md](https://github.com/portellam/deploy-vfio/tree/develop/TODO.md)).

### What is [VFIO](#VFIO?)?

#### Useful links
* [About VFIO](https://www.kernel.org/doc/html/latest/driver-api/vfio.html)
* [Guide](https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF)
* [Reddit](https://old.reddit.com/r/VFIO)

### Why?
* **Separation of Concerns**
    - Segregate your Workstation, Gaming, or School PC, as Virtual machines under one Host machine.
* **Securely run a modern OS**
    - Reduce or eliminate the negative influences an untrusted operating system (OS) may have, by reducing its access or control of real hardware.
    - Regain privacy and/or security from spyware OSes (example: *Windows 10, 11, Macintosh*).
* **Ease of use**
    - What is tedious becomes trivial; reduce the number of manual steps a user has to make.
    - Specify answers ahead of time or answer prompts step-by-step (see [Usage](#Usage:)).
* **Hardware passthrough, not Hardware emulation**
    - Preserve the performance of a virtualized OS (Gaming), through use of real hardware (Video device).
* **Quality of Life**
    - Choose multiple common-sense features that are known to experienced users (see [Features](#Features:)).
* **Your desktop OS is [Supported](#Linux:).**
* **Securely run a [Legacy OS](#Legacy:).**
* **If it's greater control of your privacy you want...**
    - Use *me_cleaner*.<sup>[1](#1)</sup>

## How-to
### To install:

        sudo bash installer.bash

### Usage:
#### * Options that skip *all* user prompts.

        Usage:        bash deploy-vfio [OPTION] [ARGUMENTS]
        Deploy a VFIO setup to a Linux Host machine that supports Para-virtualization and hardware passthrough.

          -h, --help        Print this help and exit.
          -q, --quiet       Reduce verbosity; print only relevant questions and status statements.

#### Parse IOMMU groups

        Specify the database to reference before parsing IOMMU groups.
        OPTIONS:
          -f, --file [ARGS]             Reference file database.
          -i, --internal                Reference local database.
          -o, --online                  Reference online database.

        ARGUMENTS: *
          [filename]                    Reference specific file.

          Example:
            -f some_file.txt            Reference file 'some_file.txt'.

        Specify the IOMMU groups to parse.
        OPTIONS:
          -p, --parse [groups]          Parse given IOMMU groups.

        ARGUMENTS (delimited by comma): *
          all                           Select all IOMMU groups.
          no-vga                        Select all IOMMU groups without [VGA](#VGA?) devices.
          [x]                           Select IOMMU group.
          [0-?]                         Select IOMMU groups.

          Example:
            no-vga,14                   Select group 14 and all non-VGA groups.
            1,14-16                     Select groups 1, 14, 15, and 16.


#### Pre-setup

        Pre-setup OPTIONS: *
          -c, --cpu                     Allocate CPU.
          -e, --evdev                   Setup a virtual KVM switch.
          -H, --hugepages [ARGS]        Create static hugepages (pages greater than 4 KiB) to allocate RAM for Guest(s).
          --uninstall-pre-setup         Undo changes made by preliminary setup.

        Hugepages ARGUMENTS: *
          2M, 1G                        Hugepage size (2 MiB or 1 GiB).
          [x]                           Amount of Hugepages (maximum amount is total memory subtracted by 4 GiB).

          Example:
            1G 16                       1 GiB hugepage * 16     == 16 GiB allocated to hugepages.
            2M 8192                     2 MiB hugepage * 8912   == 16 GiB allocated to hugepages.

#### VFIO setup

        VFIO setup OPTIONS: *
          -m, --multiboot [ARGS]        Create multiple VFIO setups with corresponding GRUB menu entries. Specify default GRUB menu entry by [VGA](#VGA?) IOMMU group ID (see ARGUMENTS).
          -s, --static [ARGS]           Single VFIO setup. Specify method of setup (see ARGUMENTS).
          --uninstall-vfio-setup        Undo an existing VFIO setup.

        Multiboot ARGUMENTS:"
          [x]                           The ID of the valid excluded VGA IOMMU group.
          default                       Default menu entry excludes VFIO setup.
          first                         Prefer the first valid excluded VGA IOMMU group.
          last                          Prefer the last valid excluded VGA IOMMU group.

        Static VFIO setup ARGUMENTS:
          file                          Append output to system configuration files.
          grub                          Append output to GRUB; single GRUB menu entry.

#### Post-setup

        Post-setup OPTIONS:
          --audio-loopback              Install the audio loopback service...           Loopback audio from Guest to Host (over Line-out to Line-in). *
          --auto-xorg [ARGS]            Install auto-Xorg...                            System service to find and set a valid boot [VGA](#VGA?) device for Xorg.
          --hooks                       Install recommended Libvirt hooks.
          --zram-swap [ARGS]            Create compressed swap in RAM (about 2:1)...    Reduce chances of memory exhaustion for Host.
          --uninstall-post-setup        Undo all changes made by post-setup. *

        auto-xorg ARGUMENTS:
          first  [vendor]               Find the first valid VGA device.
          last   [vendor]               Find the last valid VGA device.
          [sort] amd                    Prefer AMD or ATI.
          [sort] intel                  Prefer Intel.
          [sort] nvidia                 Prefer NVIDIA.
          [sort] other                  Prefer any other brand.

        zram-swap ARGUMENTS:
          [fraction]                    Set the fraction of total available memory.
          default                       Automatically calculate the fraction of total available memory.
          force                         Force changes, even if zram-swap is allocated and in use. *

          Example (assume a Host with 32 GiB of RAM):
            1/4 force                   Force changes and compress 8 GiB of RAM, to create 16 GiB of swap, with 16 GiB free.
            1/8                         Compress 4 GiB of RAM, to create 8 GiB of swap, with 28 GiB free.

#### * Options that skip *all* user prompts.

## Features
### Pre-setup  <sub>(vfiolib-pre-setup)</sub>:
* **Allocate CPU**
    - Reduce Host overhead, and improve both Host and Guest performance.
    - **Statically** allocate of Host CPU cores (and/or threads).<sup>[2](#2)</sup>
    - **Dynamically** allocate as a *Libvirt hook*.
* **Allocate RAM**
    - Eliminate the need to defragment Host memory (RAM) before allocating Guest memory.
    - Reduce Host overhead, and improve both Host and Guest performance.
    - **Statically** allocate Host memory to Guests.
    - Implementation is known as *Hugepages*.<sup>[3](#3)</sup>
* **Virtual KVM (Keyboard Video Mouse) switch**
    - Allow a user to swap a group of Input devices (as a whole) between active Guest(s) and Host.
    - Use the pre-defined macro (example: *'L-CTRL' + 'R-CTRL'*).
    - Create a virtual Keyboard-Video-Mouse switch.
    - Implementation is known as *Evdev (Event Devices)*.<sup>[4](#4)</sup>
    - **Disclaimer:** Guest PCI USB is good. Both implementations together is better.

### VFIO setup <sub>(vfiolib-setup)</sub>
* **Multi-boot VFIO setup**
    - Create multiple VFIO setups with corresponding GRUB menu entries.     **More flexibility.**
    - Default menu entry is without VFIO setup.
    - Best for systems with two or more PCI [VGA](#VGA?) devices.
    - Select a GRUB menu entry with a VGA device to boot from (excludes that VGA device's IOMMU group from VFIO).
    - **Disclaimer:** For best results, use *auto-Xorg*.<sup>[5](#5)</sup>
* **Static VFIO setup**
    - Single VFIO setup.                                                    **Less flexibility.**
    - Specify method of setup:
        - Append output to GRUB; single GRUB menu entry.
        - Append output to system configuration files.
    - Best for systems with integrated VGA device and one PCI VGA device.
    - Traditional PCI Passthrough/VFIO setup.

### Post-setup  <sub>(vfiolib-post-setup)</sub>:
* **auto-Xorg** system service to find and set a valid Host boot [VGA](#VGA?) device for Xorg.<sup>[5](#5)</sup>
* **Guest Audio Capture**
    - Useful for systems with multiple Audio devices.
    - Create an *Audio loopback* to output on the *Host* Audio device *Line-Out*.
    - Listen on *Host* Audio device *Line-In* (from *Guest* PCI Audio device *Line-Out*).
    - For virtual implementation, see *Virtual Audio Capture*.
* **Libvirt Hooks**
    - Invoke **"hooks"** (scripts) for all or individual Guests.<sup>[6](#6)</sup>
    - Switch display input (video output) at Guest start.
    - **Dynamically** allocate CPU cores and CPU scheduler.
    - **Libvirt-nosleep** system service(s) per Guest to prevent Host sleep while Guest is active.
* **RAM as Compressed Swapfile/partition**
    - Reduce swapiness to existing Host swap devices, and reduce chances of Host memory exhaustion (given an event of memory over-allocation).
    - Create a compressed Swap device in Host memory, using the *lz4* algorithm *(compression ratio of about 2:1)*.
    - Implementation is known as *zram-swap*.<sup>[7](#7)</sup>

## Information
### Files modified by [deploy-VFIO](#deploy-VFIO)
#### Pre-setup
- files here

#### VFIO setup
- files here

#### Post-setup
- files here

### VFIO?
Virtual Function I/O (Input Output), or VFIO, *is a new user-level driver framework for Linux...  With VFIO, a VM Guest can directly access hardware devices on the VM Host Server (pass-through), avoiding performance issues caused by emulation in performance critical paths.*<sup>[8](#8)</sup>

### VGA?
Throughout the script source code and documentation, the acronym *VGA* is used.

In Linux, a Video device or GPU, is listed as a *VGA (Video Graphics Array)*. VGA may *refer to the computer display standard, the 15-pin D-subminiature VGA connector, or the 640×480 resolution characteristic of the VGA hardware.*<sup>[9](#9)</sup>

#### Example:

    $ lspci -nnk | grep -Ei "vga|graphics"
    01:00.0 VGA compatible controller [0300]: NVIDIA Corporation GA104 [GeForce RTX 3070] [10de:2484] (rev a1)
    04:00.0 VGA compatible controller [0300]: Advanced Micro Devices, Inc. [AMD/ATI] Cayman PRO [Radeon HD 6950] [1002:6719]

### Linux:
| Distribution Family | Supported? | Tested Distros             |
| ------------------- | ---------- | -------------------------- |
| Arch                | No         | none                       |
| Debian              | Yes        | Debian 11                  |
| Gentoo              | No         | none                       |
| Red Hat             | No         | none                       |
| SUSE                | No         | none                       |

### Legacy:
| OS           | Device type    | Brand and model                          |
| ------------ | -------------- | ---------------------------------------- |
| Windows 7    | Video/graphics | NVIDIA RTX 3000-series ** or before      |
| Windows XP   | Video/graphics | NVIDIA GTX 900-series * or before**      |
|              |                | AMD Radeon HD 7000-series * or before ** |
| Windows 98   | Video/graphics | NVIDIA 7000-series GTX ** or before      |
|              |                | any ATI model **                         |

*UEFI and BIOS compatible.
**BIOS-only.

*If UEFI is enabled (and CSM/BIOS is disabled), BIOS-only VGA devices may not be available as Host video output; BIOS-only VGA devices may only be available explicitly for hardware passthrough.*

## References
### [1]
| ------------------------------------------------------------------------------------- |
| <sub>**[me_cleaner, original (GitHub)](https://github.com/corna/me_cleaner)**</sub>   |
| <sub>**[me_cleaner, updated (GitHub)](https://github.com/dt-zero/me_cleaner)**</sub>  |

### [2]
| ----------------------------------------------------------------------------------------------------------- |
| <sub>**[isolcpu (Arch wiki)](https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF#CPU_pinning)**</sub> |

### [3]
| <sub>**[Hugepages (Arch wiki)](https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF#Huge_memory_pages)**</sub> |

### [4]
| <sub>**[Evdev (Arch wiki)](https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF#Passing_keyboard/mouse_via_Evdev)**</sub> |

### [5]
| <sub>**[auto-Xorg (GitHub)](https://github.com/portellam/auto-Xorg)**</sub> |

### [6]
| <sub>**[VFIO-Tools (GitHub)](https://github.com/PassthroughPOST/VFIO-Tools)**</sub>                                                                       |
| <sub>**[libvirt-nosleep (Arch wiki)](https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF#Host_lockup_if_Guest_is_left_running_during_sleep)**</sub> |

### [7]
| <sub>**[zram-swap (GitHub)](https://github.com/foundObjects/zram-swap)**</sub>                                                                                    |
| <sub>**[lz4 (GitHub)](https://github.com/lz4/lz4)**</sub>                                                                                                         |
| <sub>**[zram package (Debian)](https://wiki.debian.org/ZRam)**</sub>                                                                                              |
| <sub>**[zram package (Arch)](https://aur.archlinux.org/packages/zramswap)**</sub>                                                                                 |
| <sub>**[zram benchmarks (Reddit)](https://web.archive.org/web/20220201101923/https://old.reddit.com/r/Fedora/comments/mzun99/new_zram_tuning_benchmarks/)**</sub> |

### [8]
| <sub>**[VFIO documentation (OpenSUSE)](https://doc.opensuse.org/documentation/leap/virtualization/html/book-virtualization/chap-virtualization-introduction.html)**</sub> |

### [9]
| <sub>**[Video Graphics Array (Wikipedia)](https://en.wikipedia.org/wiki/Video_Graphics_Array)**</sub> |

## Disclaimer:
Use at your own risk. Please review list of files modified by this script. User assumes responsbility of good backups. Please review your system's specifications and resources. Check BIOS/UEFI for Virtualization support (AMD IOMMU or Intel VT-d).