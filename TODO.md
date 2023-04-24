#### What works
* VFIO setup works (as of commit f9ca9d0).
* Pre-setup (essentials), complete and functional.
* Post-setup (extras), incomplete and mostly functional (see bugs).

#### Known bugs:
* Usage does not work with certain combinations of arguments.
* Extras:
    - Looking Glass fails to build.
    - Scream fails to build.

### To do:
#### High priority
* Maintain integrity; give credit appropriately and openly.
* Usage
    - Fix
    - Extend
    - Execute or skip setups?
    - Update for every relevant question.

#### Medium priority
* Trim fat, remove unnecessary repetitions and code.
* Essentials:
    - Evdev, save output to logfile.
* VFIO setup:
    - Detect existing setup, and recommend update or uninstall to continue.
    - VFIO output, save to logfile (for easier updating).

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