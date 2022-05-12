# Status: Work-in-progress
#
#### TODO:
* update README
* setup and list Bash Arguments for 'Auto-VFIO.sh'. Really useful for automatic setup!
* installer, should I create a system service for Auto-VFIO?
* MultiBootSetup and StaticSetup
* libvirt XML configs, as templates or cheatsheet. Tips and tricks?
#
## What is VFIO?
* See hyperlink:  https://www.kernel.org/doc/html/latest/driver-api/vfio.html
* Useful guide:   https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF
* Community:      https://old.reddit.com/r/VFIO
#
## How-to
* In terminal, execute *'sudo bash installer.sh'*
  * TODO: input details on bash arguments
#
## Auto-vfio-pci  (not included in installer yet)
**TL;DR:**
Automate VFIO passthrough setup, dynamically ('Multi-Boot') or statically.
#### Long version:
* Run at system-setup or hardware-change.
* Parses Bash for list of external PCI devices (external meaning PCI expansion devices).
* Saves relevant information: Bus ID, Hardware ID, and Kernel driver.
* User may implement:
  * Dynamic/Multi-Boot VFIO passthrough setup  **(RECOMMENDED)**
    * adds multiple GRUB menu entries for each non-passthrough VGA device, and one entry with every VGA device passed-through). 
  * Static VFIO passthrough setup.
 * Hugepages
   * static allocation of RAM for zero memory fragmentation and reduced memory latency. Best-case scenario: use whole Memory channels/sticks.
 * Event devices (Evdev)
   * virtual Keyboard-Mouse switch (best to have physical KVM and multiple PCI USB devices, better than nothing).
 * Zram swapfile
   * compressed swapfile to RAM disk, to reduce Host lock-up from over-allocated Host memory.
#
## Why?
I want to use this. It's time-consuming to setup VFIO passthrough on a new machine or Linux install.
#
