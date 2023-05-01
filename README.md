# deploy-VFIO
### Description:
Effortlessly deploy a hardware passthrough (VFIO) setup, to run Virtual machines, on your Linux computer. Includes many common-sense quality-of-life enhancements.

### Status: Functional and [Developing](https://github.com/portellam/deploy-vfio/tree/develop) (see [TODO.md](https://github.com/portellam/deploy-vfio/tree/develop/TODO.md)).

### What is VFIO?
Virtual Function I/O (Input Output), or VFIO, *is a new user-level driver framework for Linux...  With VFIO, a VM Guest can directly access hardware devices on the VM Host Server (pass-through), avoiding performance issues caused by emulation in performance critical paths.<sup>[1](https://github.com/portellam/deploy-vfio/tree/develop/#1)</sup>*

#### Useful links
* [About VFIO](https://www.kernel.org/doc/html/latest/driver-api/vfio.html)
* [Guide](https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF)
* [Reddit](https://old.reddit.com/r/VFIO)

### Why?
* **Separation of Concerns**
    - Segregate your Workstation, Gaming, or School PC, as Virtual machines under one Host machine.
* **Securely run a modern OS**
    - Reduce or eliminate the negative influences an untrusted operating system (OS) may have, by reducing its access or control of real hardware.
    - Regain privacy and/or security from spyware OSes (example: *Windows 10, 11, Macintosh*).
* **Ease of use**
    - What is tedious becomes trivial; reduce the number of manual steps a user has to make.
    - Specify answers ahead of time or answer prompts step-by-step (see [Usage](https://github.com/portellam/deploy-vfio/tree/develop/#Usage)).
* **Hardware passthrough, not Hardware emulation**
    - Preserve the performance of a Virtualized PC, through use of real hardware.
* **Quality of Life**
    - Choose multiple common-sense features that are known to experienced users (see [Features](https://github.com/portellam/deploy-vfio/tree/develop/#Features)).
* **Securely run a [Legacy](https://github.com/portellam/deploy-vfio/tree/develop/#Legacy) OS.**
* **If it's greater control of your privacy you want...**
    - Use *me_cleaner.<sup>[2](https://github.com/portellam/deploy-vfio/tree/develop/#2)</sup>*
* **Your Desktop OS is [supported](https://github.com/portellam/deploy-vfio/tree/develop/#Linux).**