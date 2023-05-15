### What works:
* Everything minus...
    - Anything mentioned in **To Do** is not enabled/available.

### To Do:
* Be certain of order of execution of source setter functions.
    - How-to: "CTRL-SHIFT-F" > "local " + some combination of the following:
        - "_"
        - "-i _"
        - "-a _"
        - "-r _"
        - "-ar _"
        - "-ir _"
    - Run before end of each source file?
    - Add conditional (inside function) to prevent overwrite?
* Naming convention, update all local vars (remove prefix underscore).
* Create Setter functions, such that they will populate publicly used params only once (when called in order)
    -This way, the script can re-execute itself?

* Trim fat, remove unnecessary repetitions and code.
* Ask question to do each function, then execute after asking all questions (pre and post-setup).
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