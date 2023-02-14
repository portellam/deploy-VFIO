## Description
Collection of custom functions to be used as libraries for Bash scripts.

## How-to
* Clone
* Use any a source [1]

[1] Documentation
* https://www.gnu.org/software/bash/manual/bash.html#index-source
* https://linuxize.com/post/bash-source-command/


## Libraries
### bashlib-all
* Is Sudo User

### bashlib-misc: Setup and command operation/validation
* Parse return code as boolean.
* Print Pass or Fail given return code.
* Save last return code.
* Stop execution after thrice failures.

### bashlib-vars: Data-type and variable validation
* Variables
    * Array Boolean, String, Number
    * Is Not Empty, Is Not Readonly [2]
* Arrays
    * Is Not Empty [2], Print [2]

### bashlib-proc: Process/library validation
* Commands, Daemons, Processes
    * Is Active, Is Installed

### bashlib-files: File operation and validation
* Files
    * Are Equal, Backup, Create Delete, Is File, Is Executable/Readable/Writable, Overwrite [2], Print, Read [2], Restore, Write [2]
* Directories
    * Create
    * Is Directory
* Find Line (in File)

### bashlib-dev: Device and Software validation
* Find package manager (set global string) by the system Linux distribution.
* Get Internet Status
* Update Internet Status and set global bool.
* Check if software package(s) exists within the package repository.
* Check if system file is original, and reinstall if false (requires connection to package repository).
* Install software package(s) from the package epository.
* Uninstall software package(s).
* Update or Clone a Git repository.

### bashlib-input: User input
* Read input (Y/n).
* Read input from range of numbers. [3]
* Read multiple-choice (ignore-case or match-case). [3]

### bashlib-globals: Global parameters
* Exit codes, for consistency in catching exceptions, error-checking, etc.
* Global variable for status of given functions ( Example: Device validation, Software validation).
* Operation status statements ( Ex: "Pass", "Fail", prefixes and suffixes ).

## Key
[2]

    input parameter is a reference ( Example: "variable_name" ), and is not "called" ( Ex: "${variable_name}" ).
[3]

    out-of-scope; call function before calling variable of exact name.

## TO-DO
    * remove out-of-scope variables. Replace with references (see Key).