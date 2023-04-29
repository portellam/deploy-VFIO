#### What works:
* Everything minus...
    - Referencing the input from usage for selecting IOMMU groups. (Input is good, just not used.)
    - Ditto with auto-Xorg (input is unused).
    - Anything mentioned in **To Do** is not enabled/available.

#### To Do:
* Trim fat, remove unnecessary repetitions and code.
* Ask question to do each function, then execute after asking all questions (pre and post-setup).
* Usage
    - Update for every relevant question.
* Pre-setup:
    - Evdev, save output to logfile, for use in VM XML.
* VFIO setup:
    - Use list from Usage input to override Parse and go straight to VFIO setup.
    - Detect existing setup, and recommend update or uninstall to continue.
    - VFIO output, read/write from/to XML file for easier updating. *
* Post-setup:
    - Create script or program to resume VM(s) from sleep?
* Errors/exceptions, handle and/or save to logfile (subjectively, important for user-operation, not development).
* Include example XML files for virtual machines?
* Include visual guides?
* Make script distro-agnostic?

#### Known Bugs:
* Extras:
    - Looking Glass fails to build. *
    - Scream fails to build. *

#### Key
* Moved to feature branch == *