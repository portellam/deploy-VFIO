### What works:
* Everything minus...
    - Anything mentioned in **To Do** is not enabled/available.

### To Do:
* hooks
    -hugepages
* Add boolean to keep track if any steps were successful and rest were skipped.
    -If true, set output to success.
* Add functionality to deploy a vfio setup with hooks? Or leave that to the pros?
* Ask question to do each function, then execute after asking all questions (pre and post-setup).
* Trim fat, remove unnecessary repetitions and code.
* Pre-setup:
    - Evdev, save output to logfile, for use in VM XML.
* VFIO setup:
    - Add Dynamic setup (not static or multiboot); Add support for VFIO bind/unbinds.
    - Detect existing setup, and recommend update or uninstall to continue.
    - Multiboot, update existing setup, upon kernel update. ***
    - VFIO output, read/write from/to XML file for easier updating. *
* Post-setup:
    - Create script or program to resume VM(s) from sleep?
* Errors/exceptions, handle and/or save to logfile (subjectively, important for user-operation, not development).
* Include example XML files for virtual machines?
* Include visual guides?
* Make script distro-agnostic?

### Known Bugs:
* VFIO setup:
    - Found behavior: Static setup fails expectedly but without warning or tripping Failure flag.
    - Given: passing all IOMMU groups (with zero VGA devices for host).
* Extras:
    - Looking Glass fails to build. *
    - Scream fails to build. *

### Key
Moved to feature branch == *
High priority == ***