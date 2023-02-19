## Status
work-in-progress

## Description
The Ultimate script to seamlessly deploy a VFIO setup (PCI passthrough). Multi-boot: Swap the preferred host graphics (VGA) device at GRUB boot menu. VFIO: Run any OS with real hardware as a Virtual machine (VM), with your desktop OS untouched.

## Why?
* **Separation-of-Concerns**
    * Segregate your Work, Game, and School PC from your personal desktop computer.
* **Run a legacy OS** should your PCI hardware support it.
    * **VGA devices:** NVIDIA GTX 900-series, or AMD Radeon HD 7000-series (or before) for **Windows XP**.
    * **VGA devices:** NVIDIA 7000-series GTX (or before), or ATI (pre-AMD) for **Windows 98**.
    * **Sound devices:** Creative Soundblaster for that authentic, 1990s-2000s experience.
* **If it's greater control of your privacy you want**
    * Piss on Bill Gates, go deploy VFIO **Now**. [9]

## How-to
To execute:

        sudo bash deploy-vfio-setup.bash

## What is VFIO?
* see hyperlink:        https://www.kernel.org/doc/html/latest/driver-api/vfio.html
* VFIO community:       https://old.reddit.com/r/VFIO
* a useful guide:       https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF

## Main VFIO Setup (PCI Passthrough)
* **Multi-boot VFIO Setup**
    * Useful for systems with multiple VGA devices (one dummy for Host, and multiple for Guest machines). **Greater flexibility.**
    * Multiple GRUB menu entries for multiple VGA device systems. Choose a GRUB menu entry with a VGA device to boot from (exclude that VGA device's IOMMU Group from PCI Passthrough/VFIO).
    * **Disclaimer:** For best results, use **Auto-Xorg**. [1]
* **Static VFIO Setup**
    * Meant for systems with a single VGA device (one dummy for Host, and one for Guest machines). **Lesser flexibility.**
    * Traditional PCI Passthrough/VFIO Setup.

## Extras (Pre- and Post-Setup)
* **Allocate CPU**
    * Reduce Host overhead, and improve both Host and Guest machine performance.
    * **Statically** allocate Host CPU cores (and/or threads). [2]
* **Allocate RAM**
    * Eliminate the need to defragment Host memory (RAM) before allocating Guest machine memory.
    * Reduce Host overhead, and improve both Host and Guest machine performance.
    * **Statically** allocate Host memory to Guest machines.
    * Implementation is known as **Hugepages**. [3]
* **Auto-Xorg** system service to find and set a valid Host boot VGA device for Xorg. [1]
* **Guest Audio Capture**
    * Useful for systems with multiple Audio devices.
    * Create an Audio loopback device to the Host's Audio device Line-Out.
    * Captures the audio stream from Guest machine PCI Audio device Line-Out to Host Sound device Line-In.
    * For virtual implementation, see **Virtual Audio Capture**.
* **Libvirt Hooks**
    * Invoke **"hooks"** (scripts) for individual Guest machines. [4]
    * Switch display input (video output) at Guest start.
    * **Dynamically** allocate system resources (CPU, RAM).
    * **Libvirt-nosleep** system service to prevent Host sleep while Guest machine(s) are active.
* **RAM as Swapfile/partition**
    * Reduce swapiness to existing Host swap devices, and reduce chances of Host memory exhaustion (given an event of memory over-allocation).
    * Create a Swap device in Host memory.
    * Implementation is known as **zram-swap**. [5]
* **Virtual KVM (Keyboard Video Mouse) switch**
    * Allow a user to swap a group of Input devices (as a whole) between active Guest machines and Host.
    * Use the pre-defined macro (example: **'L-CTRL' + 'R-CTRL'**).
    * Create a virtual Keyboard-Video-Mouse switch.
    * Implementation is known as **Evdev (Event Devices)**. [6]
    * **Disclaimer:** Guest machine PCI USB is better, and both implementations together are Best.
* **Virtual Audio Capture**
    * Setup a virtual Audio driver for Windows that provides a discrete sound device.
    * Implementation is known as **Scream**. [7]
* **Virtual Video Capture**
    * Setup direct-memory-access (DMA) of a PCI VGA device output (Video and Audio) from Guest machine to host.
    * Implementation is known as **LookingGlass**. [8]
    * **Disclaimer:** Only supported for Windows 7/10/11 Guest machines.

## References
**[1]:**    https://github.com/portellam/Auto-Xorg

**[2]:**    https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF#CPU_pinning

**[3]:**    https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF#Huge_memory_pages

**[4]:**    https://github.com/PassthroughPOST/VFIO-Tools
            https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF#Host_lockup_if_guest_is_left_running_during_sleep

**[5]:**    https://github.com/foundObjects/zram-swap
            https://wiki.debian.org/ZRam
            https://aur.archlinux.org/packages/zramswap

**[6]:**    https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF#Passing_keyboard/mouse_via_Evdev

**[7]:**    https://github.com/duncanthrax/scream

**[8]:**    https://looking-glass.io/docs/B5.0.1/

**[9]:**    https://www.youtube.com/watch?v=ShiKM3OibGQ&t=30s

## Disclaimers
Tested on Debian Linux. Works on my machine!

Please review your system's specifications and resources. Check BIOS/UEFI for Virtualization support (AMD IOMMU or Intel VT-d).