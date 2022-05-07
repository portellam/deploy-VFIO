## Status: Unfinished, Work-in-progress
# Auto-vfio-pci
## TL;DR:
Generate and/or Regenerate a VFIO setup (**Persistent** or **Multi-boot**). VFIO for Dummies

## What is VFIO?

See hyperlink:  https://www.kernel.org/doc/html/latest/driver-api/vfio.html

Useful guide:   https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF

## Long version:
Run at system-setup or whenever a hardware change occurs. Parses Bash for list of **External PCI devices** ( Bus ID, Hardware ID, and Kernel driver ). *External* refers to PCI Bus ID *01:00.0* onward.

User may implement:
* **Evdev KVM** to libvirt ( a virtual *Keyboard-video-mouse* switch ).
* **Hugepages** ( allocate system RAM *statically* for reduced memory latency ).
* **Zram swapfile** ( if user redlines host machine system resources, this change reduces/prevents occurrances of host machine lock-up ).

User may choose:
* **Persistent setup** ( modify *'/etc/modules'*, blacklists, etc. ).
* **Multi-boot setup** ( add *GRUB* menu listings ). [1]
                            
[1] *Multi-boot setup* offers flexibility with the ability to exclude a given VGA device, and boot Xorg from it ( useful for systems with more than one VGA device ). A *Persistent setup* offers less flexibility than a *Multi-boot setup*.

## Why?
  **I want to use this.** I am tired of doing this by-hand over-and-over.
  
My use-cases:
* a testbench to test old PCI devices over a PCI/PCIe bridge.
* a testbench to test VGA BIOSes without flashing ( includes adding a pointer to a VBIOS in a VM's XML file ). [2]
* swap host Xorg VGA device ( see above for *Multi-boot-setup* ).
* run Legacy OS with Legacy hardware. [3]

[2] providing a VBIOS for Windows may be necessary for NVIDIA devices, when said device's VBIOS is tainted by host startup/OS initialization.

[3] Windows XP ( GTX 900-series devices and below ), Windows 9x ( GTX 8000-series and below ).

## TO-DO:
* test
* create script for Xorg-vfio-pci ( SystemD service that regenerates Xorg at boot, finds first non vfio-pci VGA device )
* include VM XML tweaks ( that I use )
* implement features
* add Scream? ( Windows audio server to host machine client? )

