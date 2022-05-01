## Status: Work-in-progress
# Auto-vfio-pci
TL;DR:
  Runs once. Parses *lspci* for list of External PCI devices (Bus ID, Hardware ID, and Kernel driver). *External* means Bus ID *01:00.0* onward. Will append information to relevant configuration files (*/etc/default/grub*, */etc/modules*, etc.).

Why?
  **I want to use this.** I am tired of doing this by-hand over-and-over.

TO-DO:
* test!
* create separate GRUB files and title-name said files appropriately.

