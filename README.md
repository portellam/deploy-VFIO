# Status: Work-in-progress

## What is VFIO?
* See hyperlink:  https://www.kernel.org/doc/html/latest/driver-api/vfio.html
* Useful guide:   https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF
* Community:      https://old.reddit.com/r/VFIO


## How-to
* In terminal, execute *'sudo bash installer.sh'*
  * It is NOT necessary to run 'Auto-Xorg'. The service will run once at boot. See '/etc/X11/xorg.conf.d/10-Auto-Xorg.conf'.
  * You may run 'Auto-vfio-pci.sh' or 'systemctl restart Auto-vfio-pci.service'. Run once first-time or at hardware-change.
  * For 'Auto-vfio-pci.sh', see README for Bash Arguments.
#

## Auto-vfio-pci  (not included in installer yet)
**TL;DR:**
Generate and/or Regenerate a VFIO setup (**Multi-Boot** or **Static**). VFIO for Dummies.

#### Long version:
Run at system-setup or hardware-change.
Parses Bash for list of External PCI devices (Bus ID, Hardware ID, and Kernel driver). External refers to PCI Bus ID 01:00.0 onward.

User may implement:
* Multi-Boot setup (includes some Static setup) or Static setup.
  - Multi-Boot:   change Xorg VGA device on-the-fly (at boot).
  - Static:       set Xorg VGA device statically.
* Hugepages             == static allocation of RAM for zero memory fragmentation and reduced memory latency. Best-case scenario: use whole Memory channels/sticks.
* Event devices (Evdev) == virtual Keyboard-Mouse switch (best to have physical KVM and multiple PCI USB devices, better than nothing).
* Zram swapfile         == compressed RAM, to reduce Host lock-up from over-allocated Host memory.
#

## Auto-Xorg  (Status: Complete)
**TL;DR:** Generates Xorg for first available VGA device.

#### Long version;
Run Once at boot. Parses list of PCI devices, saves first VGA device (without vfio-pci driver). Appends to Xorg file ('/etc/X11/xorg.conf.d/10-Xorg-vfio-pci.conf').

Useful for **Multi-Boot** VFIO setups (see above).
#

#### Why?
  **I want to use this.**

My use-cases:
* a testbench to test old PCI devices over a PCI/PCIe bridge.
* a testbench to test VGA BIOSes without flashing ( includes adding a pointer to a VBIOS in a VM's XML file ). [1]
* swap host Xorg VGA device ( see above for *Multi-boot-setup* ).
* run Legacy OS with Legacy hardware.

[1] providing a VBIOS for Windows may be necessary for NVIDIA devices, when said device's VBIOS is tainted by host startup/OS initialization.


#### TODO:
* update README
* setup and list Bash Arguments for 'Auto-vfio-pci.sh'. Really useful for automatic setup!
* installer, should I create a system service for Auto-vfio-pci or just Auto-Xorg?
* MultiBootSetup and StaticSetup
* EvDev
* Hugepages
* ZRAM
