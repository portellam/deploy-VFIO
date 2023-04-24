## Description
Effortlessly deploy a VFIO setup (PCI passthrough). Multi-boot: Select a video card for Host at GRUB boot menu. VFIO: Run any Virtual machine with real hardware, separate from your desktop host machine.

## Status: developing
## For more information, view the [develop](https://github.com/portellam/deploy-VFIO/tree/develop) branch.

## Why?
* **Separation-of-Concerns**
    - Segregate your Work, Game, or School PC from your personal desktop computer.
* **Run a legacy OS** should your PCI hardware support it.
    - **VGA devices:** NVIDIA GTX 900-series, or AMD Radeon HD 7000-series (or before) (example: **Windows XP**).
    - **VGA devices:** NVIDIA 7000-series GTX (or before), or ATI (pre-AMD) (example: **Windows 98**).
    - **Audio devices:** Creative Soundblaster for that authentic, 1990s-2000s experience (example: **Windows 98**).
* **If it's greater control of your privacy you want**
    - Use **me_cleaner**.<sup>[1](#1)</sup>

## What is VFIO?
* about:            https://www.kernel.org/doc/html/latest/driver-api/vfio.html
* VFIO community:   https://old.reddit.com/r/VFIO
* guide:            https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF