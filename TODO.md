#### What Works:
* VFIO setup
    - Functional, each setup works as intended.
    - Will add ability to update system (parse XML document if VFIO is already setup).
* Pre-setup
    - Functional.
    - Finished.
* Post-setup
    - Mostly functional (see Known Bugs).

### To Do:
#### High priority
* Usage
    - Fix
    - Extend
    - Execute or skip setups?
    - Update for every relevant question.

#### Medium priority
* Trim fat, remove unnecessary repetitions and code.
* Essentials:
    - Evdev, save output to logfile, for use in VM XML.
* VFIO setup:
    - Detect existing setup, and recommend update or uninstall to continue.
    - VFIO output, read/write from/to XML file for easier updating.

#### Low priority
* Extras:
    - Auto-Xorg, parse arguments from user input.
* Extras:
    - Create script or program to resume VM(s) from sleep?
* Errors/exceptions, handle and/or save to logfile (subjectively, important for user-operation, not development).
* Include example XML files for virtual machines?
* Include visual guides?
* Make script distro-agnostic?

#### Known Bugs:
* Usage does not work with certain combinations of arguments.
* Extras:
    - Looking Glass fails to build.
    - Scream fails to build.

## Disclaimer
Use at your own risk.