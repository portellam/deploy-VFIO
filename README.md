## Description
Effortlessly deploy a hardware passthrough (VFIO) setup, to run Virtual machines, on your Linux computer. Includes many common-sense quality-of-life enhancements.

## Status: Functional and [Developing](https://github.com/portellam/deploy-vfio/tree/develop). See [TODO.md](https://github.com/portellam/deploy-vfio/tree/develop/TODO.md).

## Why?
* **Separation of Concerns**
    - Segregate your Workstation, Gaming, or School PC, as Virtual machines under one Host machine.
* **Securely run a modern OS**
    - Reduce or eliminate the negative influences an untrusted operating system (OS) may have, by reducing its access or control of real hardware.
    - Regain privacy and/or security from spyware OSes (example: Windows 10, 11, Macintosh).
* **Ease of use**
    - What is tedious becomes trivial; reduce the number of manual steps a user has to make.
    - Specify answers ahead of time or answer prompts step-by-step (see [Usage](https://github.com/portellam/deploy-vfio/tree/develop/#Usage)).
* **Hardware passthrough, not Hardware emulation**
    - Preserve the performance of a Virtual machine PC, through use of real hardware.
* **Quality of Life**
    - Choose multiple common-sense features that are known to experienced users (see [Features](https://github.com/portellam/deploy-vfio/tree/develop/#Features)).
* **Securely run a legacy OS**
    - For hardware passthrough, see below.
    - **Video devices:** NVIDIA GTX 900-series, or AMD Radeon HD 7000-series (or before) (example: **Windows XP**).
    - **Video devices:** NVIDIA 7000-series GTX (or before), or ATI (pre-AMD) (example: **Windows 98**).
    - **Audio devices:** Creative Soundblaster for that authentic, 1990s-2000s experience (example: **Windows 98**).
* **If it's greater control of your privacy you want**
    - Use **me_cleaner**.<sup>[1](https://github.com/portellam/deploy-vfio/tree/develop/#1)</sup>

## What is VFIO?
* about:            https://www.kernel.org/doc/html/latest/driver-api/vfio.html
* VFIO community:   https://old.reddit.com/r/VFIO
* guide:            https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF