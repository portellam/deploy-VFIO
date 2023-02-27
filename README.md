## Status
work-in-progress

## Description
The Ultimate script to seamlessly deploy a VFIO setup (PCI passthrough). Multi-boot: For multiple VGA **(GPU)** device systems, Swap the preferred Host VGA device at GRUB boot menu. VFIO: Run any OS with PCI hardware as a Virtual machine (VM), with your desktop OS untouched.

## Why?
* **Separation-of-Concerns**
    * Segregate your Work, Game, and School PC from your personal desktop computer.
* **Run a legacy OS** should your PCI hardware support it.
    * **VGA devices:** NVIDIA GTX 900-series, or AMD Radeon HD 7000-series (or before) (example: **Windows XP**).
    * **VGA devices:** NVIDIA 7000-series GTX (or before), or ATI (pre-AMD) (example: **Windows 98**).
    * **Audio devices:** Creative Soundblaster for that authentic, 1990s-2000s experience (example: **Windows 98**).
* **If it's greater control of your privacy you want**
    * Piss on Microsoft, go deploy a VFIO setup **NOW**. [9]
    * Use **me_cleaner**. [10]

## What is VFIO?
* about:            https://www.kernel.org/doc/html/latest/driver-api/vfio.html
* VFIO community:   https://old.reddit.com/r/VFIO
* guide:            https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF

## How-to
To execute:

        sudo bash deploy-vfio-setup.bash

## Features
### Main VFIO Setup (PCI Passthrough)
* **Multi-boot VFIO Setup**
    * Best for Multiple VGA PCI Passthrough (**one** VGA for Host, and **multiple** VGA for Guests).    **More flexibility.**
    * Multiple GRUB menu entries for multiple VGA device systems. Choose a GRUB menu entry with a VGA device to boot from (exclude that VGA device's IOMMU Group from PCI Passthrough/VFIO).
    * **Disclaimer:** For best results, use **Auto-Xorg**. [1]
* **Static VFIO Setup**
    * Best for Single VGA PCI Passthrough (**one** VGA for Host, and **one** VGA for Guests).           **Less flexibility.**
    * Traditional PCI Passthrough/VFIO Setup.

### Extras (Pre- and Post-Setup)
* **Allocate CPU**
    * Reduce Host overhead, and improve both Host and Guest performance.
    * **Statically** allocate Host CPU cores (and/or threads). [2]
* **Allocate RAM**
    * Eliminate the need to defragment Host memory (RAM) before allocating Guest memory.
    * Reduce Host overhead, and improve both Host and Guest performance.
    * **Statically** allocate Host memory to Guests.
    * Implementation is known as **Hugepages**. [3]
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
* **Virtual KVM (Keyboard Video Mouse) switch**
    * Allow a user to swap a group of Input devices (as a whole) between active Guest(s) and Host.
    * Use the pre-defined macro (example: **'L-CTRL' + 'R-CTRL'**).
    * Create a virtual Keyboard-Video-Mouse switch.
    * Implementation is known as **Evdev (Event Devices)**. [6]
    * **Disclaimer:** Guest PCI USB is good. Both implementations together is better.
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
* **Ford attacks Chevy:**   https://www.youtube.com/watch?v=ShiKM3OibGQ&t=30s

### [10]
* **original:**     https://github.com/corna/me_cleaner
* **updated fork:** https://github.com/dt-zero/me_cleaner

## Disclaimers
Use at your own risk.
Please review your system's specifications and resources. Check BIOS/UEFI for Virtualization support (AMD IOMMU or Intel VT-d).

## Contribution
Should you find this script useful, please reach out via the **Issues** tab on GitHub. Thank you.