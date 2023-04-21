#### What works
* No-GRUB Static setup works.
* Pre-setup (essentials), complete and functional.
* Post-setup (extras), incomplete and mostly functional (see bugs).

#### Known bugs:
* Usage does not work with certain combinations of arguments.
* Extras:
    - Looking Glass fails to build.
    - Scream fails to build.
* VFIO setups:
    - Static GRUB setup fails.
    - Multiboot setup fails.
    - Symptom is devices aren't binded to vfio-pci.
    - Possible kernel commandline syntax error.

### To do:
#### High priority
* VFIO setups
    - Fix bugs.
* Backups:
    - Restore files properly, on exit (failure).
* Usage
    - Fix
    - Extend
    - Execute or skip setups?
    - Update for every relevant question.

#### Medium priority
* CPU isolation, ask user to setup Static (append to GRUB) or Dynamic (Libvirt hooks).
* Trim fat, remove unnecessary repetitions and code.
* Extras:
    - Libvirt hooks, add more.
* VFIO setup:
    - Detect existing setup, and recommend update or uninstall to continue.
    - VFIO output, save to logfile (for easier updating).
    - Save as XML?

#### Low priority
* Extras:
    - Auto-Xorg, parse arguments from user input.
* Extras:
    - Create script or program to resume VM(s) from sleep?
* Errors/exceptions, handle and/or save to logfile (subjectively, important for user-operation, not development).
* Include example XML files for virtual machines?
* Include visual guides?
* Make script distro-agnostic?
* Skip pre-setup and post-setup installations if already done (from previous setup).

## Disclaimer
Use at your own risk.