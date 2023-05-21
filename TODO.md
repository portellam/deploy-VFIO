### What works:
* Everything minus...
    - Anything mentioned in **To Do** is not enabled/available.

### To Do:
* VFIO setup
    - Fix static setup
* Output evdev to logfile for reference by user? Or dump into VM XML friendly format?
* Post-setup:
    - Create script or program to resume VM(s) from sleep?
* Errors/exceptions, handle and/or save to logfile (subjectively, important for user-operation, not development).
* Include example XML files for virtual machines?
* Include visual guides?
* Make script distro-agnostic?

### Known Bugs:
* Static setup (new parse broke some things)
* Extras:
    - Looking Glass fails to build. *
    - Scream fails to build. *

### Key
Moved to feature branch == *
High priority == ***