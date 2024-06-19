# Deploy VFIO
### v1.0.1
Effortlessly deploy a hardware-passthrough (VFIO) setup for Virtual Machines
(VMs) on a Linux desktop. Includes quality-of-life enhancements that you didn't
think you need!

**Download the Latest Release:**&ensp;[Codeberg][codeberg-releases],
[GitHub][github-releases]

[codeberg-releases]: https://codeberg.org/portellam/libvirt-hooks/releases/latest
[github-releases]:   https://github.com/portellam/libvirt-hooks/releases/latest

## Table of Contents
- [Why?](#why)
- [Related Projects](#related-projects)
- [Documentation](#documentation)
- [Host Requirements](#host-requirements)
- [Download](#download)
- [Usage](#usage)
- [Features](#features)
- [Information](#information)
- [Disclaimer](#disclaimer)
- [Contact](#contact)
- [References](#references)

## Contents
### Why?
1. **Separation of Concerns:** Independently operate your workstation, gaming,
and school Operating Systems (OS), as [Virtual Machines](#10) (VMs), under one
Host machine.

2. **No Need for a Server**
  - Keep your Host OS **desktop** experience intact; turns your Host into a
  *Type-2* [Hypervisor](#17).
  - Servers like Microsoft Hyper-V, Oracle VM, and Proxmox Linux are considered
  *Type-1* or bare-metal Hypervisors.

3. **Securely run a an OS**
  - Limited access to real hardware means greater security.
  - The benefits extend to untrusted or legacy OSes.

4. **Ease of use:** support for automation by use of the
[Command Line Interface](#usage) (CLI).

5. **PCI Passthrough:** prioritize real hardware over emulation.

6. **Quality of Life**: utilize multiple common-sense [features](#features) that
are known to experienced users.

7. **Your Host OS is [supported](#host-requirements).**

**Note:** For even greater security, use [me_cleaner](#8) alongside a VFIO
setup.

**Disclaimer:** See [below] for supported [VGA](#20) devices.

[below]: (#latest-graphics-hardware-for-various-guest-operating-systems)

### Related Projects
| Project                             | Codeberg          | GitHub          |
| :---                                | :---:             | :---:           |
| **Deploy VFIO**                     | [link][codeberg1] | [link][github1] |
| Auto X.Org                          | [link][codeberg2] | [link][github2] |
| Generate Evdev                      | [link][codeberg3] | [link][github3] |
| Guest Machine Guide                 | [link][codeberg4] | [link][github4] |
| Libvirt Hooks                       | [link][codeberg5] | [link][github5] |
| Power State Virtual Machine Manager | [link][codeberg6] | [link][github6] |

[codeberg1]: https://codeberg.org/portellam/deploy-VFIO
[github1]:   https://github.com/portellam/deploy-VFIO
[codeberg2]: https://codeberg.org/portellam/auto-xorg
[github2]:   https://github.com/portellam/auto-xorg
[codeberg3]: https://codeberg.org/portellam/generate-evdev
[github3]:   https://github.com/portellam/generate-evdev
[codeberg4]: https://codeberg.org/portellam/guest-machine-guide
[github4]:   https://github.com/portellam/guest-machine-guide
[codeberg5]: https://codeberg.org/portellam/libvirt-hooks
[github5]:   https://github.com/portellam/libvirt-hooks
[codeberg6]: https://codeberg.org/portellam/powerstate-virtmanager
[github6]:   https://github.com/portellam/powerstate-virtmanager

### Documentation
- [What is VFIO?](#18)
- [VFIO Forum](#12)
- [PCI Passthrough Guide](#11)

## Host Requirements
- Currently supported operating systems:
  | Linux Distributions  | Tested | Supported  |
  | :------------------- | :----: | :--------: |
  | Arch                 | No     | none       |
  | Debian<sup>[1]</sup> | Yes    | 11, 12     |
  | Gentoo               | No     | none       |
  | Red Hat Enterprise   | No     | none       |
  | SUSE                 | No     | none       |

[1]: (#1-debian-derivatives-include-linux-mint-pop-os-and-ubuntu)

##### 1. Debian derivatives include Linux Mint, Pop! OS, and Ubuntu.

- Required software packages (for this script):
  `xmlstarlet`
  - To install packages:
    - Debian Linux: `sudo apt install -y xmlstarlet`

- Other requirements:
  - `GRUB` to execute command lines at boot (if chosen).
  - `systemd` for system services.

  - IOMMU is supported (by the CPU) and enabled in the motherboard firmware
  (BIOS or UEFI).
    - For AMD machines:&nbsp;`AMD-Vi`
    - For Intel machines:&ensp;&nbsp;`VT-d`
    - ARM (`SMMU`) and other CPU architectures are not explicitly supported by this
    script.

### Download
- To download this script, you may:
  - Download the Latest Release:&ensp;[Codeberg][codeberg-releases],
[GitHub][github-releases]

  - Download the ZIP file:
    1. Viewing from the top of the repository's (current) webpage, click the
       drop-down icon:
      - `···` on Codeberg.
      - `<> Code ` on GitHub.

    2. Click `Download ZIP`. Save this file.

    3. Open the `.zip` file, then extract its contents.

  - Clone the repository:
    1. Open a Command Line Interface (CLI).
      - Open a console emulator (for Debian systems: Konsole).

      - Open a existing console: press `CTRL` + `ALT` + `F2`, `F3`, `F4`, `F5`,
      or `F6`.
        - **To return to the desktop,** press `CTRL` + `ALT` + `F7`.
        - `F1` is reserved for debug output of the Linux kernel.
        - `F7` is reserved for video output of the desktop environment.
        - `F8` and above are unused.

    2. Change your directory to your home folder or anywhere safe: `cd ~`

    3. Clone the repository:
      - `git clone https://www.codeberg.org/portellam/deploy-VFIO`
      - `git clone https://www.github.com/portellam/deploy-VFIO`

- To make this script executable, you must:
  1. Open the CLI (see above).

  2. Go to the directory of where the cloned/extracted repository folder is:
  `cd name_of_parent_folder/deploy-VFIO/`

  3. Make the installer script file executable: `chmod +x installer.bash`
    - Do **not** make any other script files executable. The installer will perform
    this action.
    - Do **not** make any non-script file executable. This is not necessary and
    potentially dangerous.

### Usage
**`installer.bash`**
  - From the project folder, execute: `sudo bash installer.bash`
  ```xml
  -h, --help               Print this help and exit.
  -i, --install            Install deploy-VFIO to system.
  -u, --uninstall          Uninstall deploy-VFIO from system.
  ```
  - The installer will place all script files in `/usr/local/bin`.
  - The installer will place all configuration/text files in `/usr/local/etc`.

**`deploy-VFIO`**
- From anywhere, execute: `sudo bash deploy-VFIO`
  - The CLI's shell (bash) should recognize that the script file is located in
  `/usr/local/bin`.
```
-h, --help               Print this help and exit.
-q, --quiet              Reduce verbosity; print only relevant questions and
status statements.
-u, --undo               Undo changes (restore files) if script has exited early
or unexpectedly.
  --ignore-distro        Ignore distribution check for Debian or Ubuntu system.

Specify the database to reference before parsing IOMMU groups:
  --xml [filename]       Cross-reference XML file. First-time, export if VFIO is
  not setup. Consecutive-times, imports if VFIO is setup.
  [filename]             Reference specific file.
  --no-xml               Skips prompt.

Specify the IOMMU groups to parse:
-p, --parse [groups]     Parse given IOMMU groups (delimited by comma).
  all                    Select all IOMMU groups.
  no-vga                 Select all IOMMU groups without VGA devices.
  [x]                    Select IOMMU group.
  [x-y]                  Select IOMMU groups.

Example:
  --parse no-vga,14      Select IOMMU group 14 and all non-VGA groups.
  --parse 1,14-16        Select IOMMU groups 1, 14, 15, and 16.

Pre-setup:
-c, --cpu                Allocate CPU.
-e, --evdev              Setup a virtual KVM switch.
-h, --hugepages [ARGS]   Create static hugepages (pages greater than 4 KiB) to
allocate RAM for Guest(s).
  --skip-pre-setup       Skip execution.
  --uninstall-pre-setup  Undo all changes made by pre-setup.

Hugepages:
  2M, 1G                 Hugepage size (2 MiB or 1 GiB).
  [x]                    Amount of Hugepages (maximum amount is total memory
  subtracted by 4 GiB).

Example:
--hugepages 1G 16        1 GiB hugepage 16   == 16 GiB allocated to hugepages.
--hugepages 2M 8192      2 MiB hugepage 8912 == 16 GiB allocated to hugepages.

VFIO setup:
-m, --multiboot [ARGS]   Create multiple VFIO setups with corresponding GRUB
menu entries. Specify default GRUB menu entry by VGA IOMMU group ID.
-s, --static [ARGS]      Single VFIO setup. Specify method of setup.
--skip-vfio-setup        Skip execution.
--uninstall-vfio-setup   Undo an existing VFIO setup.

Multiboot VFIO:
  [x]                    The ID of the valid excluded VGA IOMMU group.
  default                Default menu entry excludes VFIO setup.
  first                  Prefer the first valid excluded VGA IOMMU group.
  last                   Prefer the last valid excluded VGA IOMMU group.

Static VFIO:
  file                   Append output to system configuration files.
  grub                   Append output to GRUB; single GRUB menu entry.
```

### Features
#### Pre-setup
1. **Allocate CPU**
  - **Statically** isolate Host CPU threads before allocating to Guest(s).
  -  Reduces Host overhead, and improves both Host and Guest performance.
  -  If installed, the **Dynamic** [Libvirt hook](#5) (see source) will skip its
  execution, to preserve the Static isolation.

  2. **Allocate RAM**
  - **Static** huge memory pages eliminate the need to defragment Host memory
  (RAM) before allocating to Guest(s).
  - Reduces Host overhead, and improves both Host and Guest performance.
  - If skipped, setup will install the Libvirt hook for **Dynamic** allocation
  (transparent hugepages).

3. **Virtual Keyboard Video Mouse (KVM) switch**
  - Create a virtual KVM switch.
    - Allow a user to swap a group of Input devices (as a whole) between active
    Guest(s) and Host.
    - Set and use a [defined macro](#23).
      - Default macro: `L-CTRL` + `R-CTRL`

  - Implementation is known as [Evdev](#2) (Event Devices).
  - **Note:** Using guest PCI USB alone is good. Using both implementations is
  better.

#### Main setup
- **Multi-boot VFIO setup**
  - Create multiple VFIO setups with corresponding GRUB menu entries.
  **More flexibility.**
    - Select a GRUB menu entry with a VGA device excluded from VFIO.
    - Default menu entry is without VFIO setup.
    - Best for systems with two or more PCI VGA devices, without an integrated VGA
    device (iGPU).

  - **Ad:** For best results, use [Auto X.Org](#1).

- **Static VFIO setup**
  - Single, traditional VFIO setup. **Less flexibility.**
  - Specify method of setup:
    - Append output to GRUB; single GRUB menu entry.
    - Append output to system configuration files.

  - Best for systems with one or more PCI VGA device(s) and one integrated VGA
  device (iGPU).

- **Dynamic VFIO setup** (To be implemented in a future release)
  - Use Libvirt hooks to bind or unbind devices at Guest(s) start or stop.
  - Most responsibility; best for more experienced users.
  - Most flexibility; Libvirt hooks allow Host to allocate and release resources
  dynamically.
  - For an existing script of similar scope, you may try the project
  [VFIO-Tools](#19).

#### Post-setup (To be implemented in a future release)
1. **Auto X.Org** system service to find and set a valid Host boot [VGA](#20)
device for X.Org.

2. **Guest Audio Capture**
  - Create an [audio loopback](#22) to output on the Host audio device Line-Out.
    - Listen on Host audio device Line-In (from Guest PCI Audio device Line-Out).
    - Useful for systems with multiple audio devices.

  - For virtual implementation, see *Virtual Audio Capture*.

3. **Libvirt Hooks**
- Invoke [hooks](#5) or scripts for all or individual Guests.
- Switch display input (video output) at Guest start.
- **Dynamically** allocate CPU cores and prioritize CPU scheduler.
- **Libvirt-nosleep**: per Guest system service, to prevent Host sleep while
Guest is active.

4. **RAM as Compressed Swapfile/partition**
  - Create a compressed Swap device in Host memory, using the [lz4](#6) algorithm
  (compression ratio of about 2:1).
    - Reduce swapiness to existing Host swap devices.
    - Reduce chances of Host memory exhaustion (given an event of memory
    over-allocation).

  - Implementation is known as [zram-swap](#21).

5. **Virtual Audio Capture**
  - Setup a virtual audio driver for Windows that provides a discrete audio
  device.
  - Implementation is known as [Scream](#14).

6. **Virtual Video Capture**
  - Setup direct-memory-access (DMA) of a PCI VGA device output (video and audio)
  from a Guest to Host.
  - Implementation is known as [Looking Glass](#7).
  - **Disclaimer:** Only supported for Guests running Windows 7 and later
  (Windows NT 6.1+).

### Information
#### BIOS v. UEFI
- Some VGA devices, such as NVIDIA, may not be recognizable in a VM, as the
video BIOS or VBIOS is *tainted* at Host OS start-up. This is usually the case
if a given VGA device is used for the Host BIOS/UEFI booting process. To remedy
this, you must obtain a clean copy of the VBIOS. You may review either
[NVIDIA-vBIOS-VFIO-Patcher](#9), or the [ArchWiki](#11).

- If your Host machine supports UEFI only and/or if UEFI is enabled
(and CSM/BIOS is disabled), BIOS-only VGA devices may not be available as Host
video output. BIOS-only VGA devices may only be available explicitly for
hardware passthrough.

### Filenames and pathnames modified:
#### Pre-setup files
  - `/etc/apparmor.d/local/abstractions/libvirt-qemu`
  - `/etc/libvirt/qemu.conf`

#### VFIO setup files
  - `/etc/default/grub`
  - `/etc/grub.d/proxifiedScripts/custom`
  - `/etc/initramfs-tools/modules`
  - `/etc/modprobe.d/pci-blacklists.conf`
  - `/etc/modprobe.d/vfio.conf`
  - `/etc/modules`

#### Post-setup paths
  - `/etc/libvirt/hooks/`
  - `/usr/local/bin/`
  - `/etc/systemd/system/`

#### Paths for project binaries and files
  - `/usr/local/bin/`
  - `/usr/local/etc/deploy-VFIO.d`

##### Example
`lspci -nnk | grep --extended-regexp --ignore-case "vga|graphics"`

##### Output:
```
01:00.0 VGA compatible controller [0300]: NVIDIA Corporation GA104 [GeForce RTX 3070] [10de:2484] (rev a1)
04:00.0 VGA compatible controller [0300]: Advanced Micro Devices, Inc. [AMD/ATI] Cayman PRO [Radeon HD 6950] [1002:6719]
```

#### Latest graphics hardware for various Guest Operating Systems
##### Apple Macintosh
###### [AMD and NVIDIA GPU compatibility list](#3)
###### [More detailed NVIDIA GPU compatibility list](#13)

##### Microsoft Windows
| Windows version        | Device type | Brand and model                           |
| --------------------   | ----------- | ----------------------------------------- |
| 10 and above or NT 10+ | VGA         | NVIDIA RTX 4000-series[<sup>2</sup>](#2-uefi-only) or before       |
| 7 and above or NT 6.1+ | VGA         | NVIDIA RTX 1000-series[<sup>2</sup>](#2-uefi-only) or before       |
| XP or NT 4             | VGA         | NVIDIA GTX 900-series[<sup>3</sup>](#3-uefi-or-bios-compatible) or before[<sup>3</sup>](#3-uefi-or-bios-compatible)          |
|                        |             | AMD Radeon HD 7000-series[<sup>3</sup>](#3-uefi-and-or-compatible) or before[<sup>3</sup>](#3-uefi-or-bios-compatible) |
| 9x                     | VGA         | NVIDIA 7000-series GTX[<sup>1</sup>](#1-bios-only) or before       |
|                        |             | any ATI model[<sup>1</sup>](#1-bios-only) (before AMD)             |

##### 1. *BIOS only.*
##### 2. *UEFI only.*
##### 3. *UEFI or BIOS compatible.*

**Note:** For emulating video devices on Windows 9x and older legacy operating
systems, try the [SoftGPU](#15). Modern CPUs are more than powerful enough to
emulate such hardware.

### Disclaimer
Use at your own risk. Please review your system's specifications and resources.

### Contact
Did you encounter a bug? Do you need help? Please visit the **Issues page**
([Codeberg][codeberg-issues], [GitHub][github-issues]).

[codeberg-issues]: https://codeberg.org/portellam/deploy-VFIO/issues
[github-issues]:   https://github.com/portellam/deploy-VFIO/issues

### References
#### 1.
**portellam/auto-xorg.** Codeberg. Accessed June 18, 2024.
<sup>https://codeberg.org/portellam/auto-xorg.

**portellam/auto-xorg.** GitHub. Accessed June 18, 2024.
<sup>https://github.com/portellam/auto-xorg.

#### 2.
**portellam/generate-evdev**. Codeberg. Accessed June 17, 2024.
<sup>https://codeberg.org/portellam/generate-evdev.</sup>

**portellam/generate-evdev**. GitHub. Accessed June 17, 2024.
<sup>https://github.com/portellam/generate-evdev.</sup>

#### 3.
**Graphics card compatibility for Final Cut Pro, Motion, and Compressor**. Apple
Support. October 31, 2023. Accessed June 18, 2024.
<sup>https://support.apple.com/en-us/102734.</sup>

#### 4.
**Hugepages**. Debian Wiki. Accessed June 17, 2024.
<sup>https://wiki.debian.org/Hugepages.</sup>

**Huge memory pages**. PCI passthrough via OVMF - ArchWiki. Accessed June 14,
2024.
<sup>https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF#Huge_memory_pages.</sup>

#### 5.
**portellam/libvirt-hooks.** Codeberg. Accessed June 18, 2024.
<sup>https://codeberg.org/portellam/libvirt-hooks.</sup>

**portellam/libvirt-hooks.** GitHub. Accessed June 18, 2024.
<sup>https://github.com/portellam/libvirt-hooks.</sup>

#### 6.
**LZ4/LZ4: Extremely Fast Compression Algorithm**. GitHub. Accessed June 17,
2024.
<sup>https://github.com/lz4/lz4.</sup>

#### 7.
**Looking Glass**. Looking Glass. Accessed June 17, 2024.
<sup>https://looking-glass.io/</sup>

#### 8.
**corna/me_cleaner**. GitHub. Accessed June 17, 2024.
<sup>https://github.com/corna/me_cleaner.</sup>

**dt-zero/me_cleaner**. GitHub. Accessed June 17, 2024.
<sup>https://github.com/dt-zero/me_cleaner.</sup>

#### 9.
**Matoking/NVIDIA-vBIOS-VFIO-Patcher**: GitHub. Accessed June 18, 2024.
<sup>https://github.com/Matoking/NVIDIA-vBIOS-VFIO-Patcher.</sup>

#### 10.
**4.5 Passing Keyboard/Mouse via Evdev**. PCI passthrough via OVMF - ArchWiki.
Accessed June 14, 2024.
<sup>https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF.</sup>

#### 11.
**PCI passthrough via OVMF**. ArchWiki. Accessed June 14, 2024.
<sup>https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF.</sup>

#### 12.
**r/VFIO**. Accessed June 14, 2024.
<sup>https://www.reddit.com/r/VFIO/.</sup>

#### 13.
**tonymacx86 - Will my Nvidia Graphics Card work with macOS ? List of Desktop**
**Cards with Native Support** Archive.org. Accessed June 18, 2024.
<sup>https://web.archive.org/web/20230926193339/https://www.tonymacx86.com/threads/will-my-nvidia-graphics-card-work-with-macos-list-of-desktop-cards-with-native-support.283700/.

#### 14.
**duncanthrax/scream**. GitHub. Accessed June 17, 2024.
<sup>https://github.com/duncanthrax/scream.</sup>

#### 15.
**JHRobotics/SoftGPU**. GitHub. Accessed June 17, 2024.
<sup>https://github.com/JHRobotics/SoftGPU.</sup>

#### 16.
**Using Scream Over LAN**. Looking Glass. Accessed June 17, 2024.
<sup>https://looking-glass.io/wiki/Using_Scream_over_LAN.</sup>

#### 17.
**Type 1 vs. Type 2 hypervisors**. IBM. Accessed June 18, 2024.
<sup>https://www.ibm.com/topics/hypervisors.</sup>

#### 18.
**VFIO - ‘Virtual Function I/O’ - The Linux Kernel Documentation**.
The linux kernel. Accessed June 14, 2024.
<sup>https://www.kernel.org/doc/html/latest/driver-api/vfio.html.</sup>

**Virtualization technology**. OpenSUSE Leap 15.5. Accessed June 18, 2024.
<sup>https://doc.opensuse.org/documentation/leap/virtualization/html/book-virtualization/chap-virtualization-introduction.html.</sup>

#### 19.
**PassthroughPOST/VFIO-Tools.** GitHub. Accessed June 18, 2024.
<sup>https://github.com/PassthroughPOST/VFIO-Tools.</sup>

#### 20.
**Video Graphics Array**. Wikipedia. August 18, 2002. Accessed June 18, 2024.
<sup>https://en.wikipedia.org/wiki/Video_Graphics_Array.</sup>

#### 21.
**foundObjects/zram-swap**. GitHub. Accessed June 17, 2024.
<sup>https://github.com/foundObjects/zram-swap.</sup>

**New zram tuning benchmarks**. Reddit. Accessed June 17, 2024.
<sup>https://web.archive.org/web/20220201101923/https://old.reddit.com/r/Fedora/comments/mzun99/new_zram_tuning_benchmarks/.</sup>

**zramswap**. Arch Linux User Repository. Accessed June 17, 2024.
<sup>https://aur.archlinux.org/packages/zramswap.</sup>

#### 22.
**portellam/audio-loopback.** Codeberg. Accessed June 18, 2024.
<sup>https://codeberg.org/portellam/audio-loopback.

**portellam/audio-loopback.** GitHub. Accessed June 18, 2024.
<sup>https://github.com/portellam/audio-loopback.

#### 23.
**libvirt/libvirt - Input Devices**. GitHub. Accessed June 18, 2024.
<sup>https://github.com/libvirt/libvirt/blob/master/docs/formatdomain.rst#input-devices.</sup>