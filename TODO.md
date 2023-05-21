### To Do:
* Important
    * test support for cross-distro/distro-agnosticism.
    * allow for skips of certain subfunctions.
    * test automation.
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
* Post-setup:
    - Looking Glass fails to build.
    - Scream fails to build.