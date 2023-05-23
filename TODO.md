### To Do:
* Important
    * Test options and args.
    * Test across distros.
    * Allow for skips of certain subfunctions.
    * Post-setup:
        - Looking Glass
        - Scream
* Nice-to-haves:
    * VGA BIOS dumping and prep for VFIO.
        - Important for pre 2022/2021 NVIDIA firmware/drivers.
        - Also important for early UEFI/late BIOS graphics devices.
    * Output information for virsh xml
        - Evdev
        - Isolcpu
        - Hugepages
        - Recommended tweaks
        - Looking Glass
        - Scream
        - VM spoofing
    * Include example virsh xml files
    * Include visual guides?
    * Post-setup:
        - Create script to resume VM(s) from sleep?
    * Errors/exceptions, handle and/or save to logfile (subjectively, important for user-operation, not development).


### Known Bugs:
* Some options and args are not working as before.
    - Parse does not fill out automatically.
* VFIO setup:
    - Error prompt at start of custom GRUB entry. Does not stop or negatively affect execution.
* Post-setup:
    - Looking Glass fails to build.
    - Scream fails to build.