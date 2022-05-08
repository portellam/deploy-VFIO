## Status: Unfinished, Work-in-progress
# Auto-vfio-pci
## TL;DR:
Generate and/or Regenerate a VFIO setup (**Multi-Boot** or **Static**). VFIO for Dummies.

## What is VFIO?

See hyperlink:  https://www.kernel.org/doc/html/latest/driver-api/vfio.html

Useful guide:   https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF

Community:      https://old.reddit.com/r/VFIO

## Long version:
Run at system-setup or hardware-change.
Parses Bash for list of External PCI devices ( Bus ID, Hardware ID, and Kernel driver ). External refers to PCI Bus ID 01:00.0 onward.

User may implement:
* Multi-Boot setup (includes some Static setup) or Static setup.
  - Multi-Boot:   change Xorg VGA device on-the-fly (at boot).
  - Static:       set Xorg VGA device statically.
* Hugepages             == static allocation of RAM for zero memory fragmentation and reduced memory latency. Best-case scenario: use whole Memory channels/sticks.
* Event devices (Evdev) == virtual Keyboard-Mouse switch.
* Zram swapfile         == compressed RAM, to reduce Host lock-up from over-allocated Host memory.

## Why?
  **I want to use this.**
  
My use-cases:
* a testbench to test old PCI devices over a PCI/PCIe bridge.
* a testbench to test VGA BIOSes without flashing ( includes adding a pointer to a VBIOS in a VM's XML file ). [2]
* swap host Xorg VGA device ( see above for *Multi-boot-setup* ).
* run Legacy OS with Legacy hardware. [3]

[2] providing a VBIOS for Windows may be necessary for NVIDIA devices, when said device's VBIOS is tainted by host startup/OS initialization.

[3] Windows XP ( GTX 960 ), Windows 9x ( 8400 GS ).

## TO-DO:
* tests
* StaticSetup
* EvDev
* zRAM
* Xorg
