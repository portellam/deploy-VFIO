## Status: Unfinished, Work-in-progress
# Auto-vfio-pci
## TL;DR:
Generate and/or Regenerate a VFIO setup (**Persistent** or **Multi-boot**). VFIO for Dummies

## What is VFIO?

See hyperlink: https://www.kernel.org/doc/html/latest/driver-api/vfio.html

## Long version:
Run at system-setup or whenever a hardware change occurs. Parses Bash for list of **External PCI devices** ( Bus ID, Hardware ID, and Kernel driver ). *External* refers to PCI Bus ID *01:00.0* onward.
User may implement
* **Evdev KVM** to libvirt ( a virtual *Keyboard-video-mouse* switch ).
* **Hugepages** ( allocate system RAM *statically* for reduced memory latency ).
* **Zram swapfile** ( if user redlines host machine system resources, this change reduces/prevents occurrances of host machine lock-up ).

User may choose between a
* **Persistent setup** ( modify *'/etc/modules'*, blacklists, etc. ).
* **Multi-boot setup** ( add *GRUB* menu listings ). [1]
                            
[1] *Multi-boot setup* offers flexibility with the ability to exclude a given VGA device, and boot Xorg/Display Manager from it ( useful for systems with more than one VGA device ). A *Persistent setup* offers less flexibility than a *Multi-boot setup*.

## Why?
  **I want to use this.** I am tired of doing this by-hand over-and-over.
  
My use-cases include:
* a testbench to test old PCI devices over a PCI/PCIe bridge.
* a testbench to test VGA BIOSes without flashing ( includes adding a pointer to a VBIOS in a VM's XML file ). [2]
* swap host Xorg VGA device, to run an older OS which cannot support modern VGA devices. [3]

[2] providing a VBIOS for Windows may be necessary for NVIDIA devices, when said device is initialized at host BIOS/UEFI startup.

[3] Windows XP x86 ( GTX 900-series devices and below, and Radeon RX 200(?)-series devices and below )

## TO-DO:
* test
* create script for Xorg-vfio-pci ( SystemD service that regenerates Xorg at boot, finds first non vfio-pci VGA device )
* include VM XML tweaks ( that I use )
* implement features
* add Scream? ( Windows audio server to host machine client? )

