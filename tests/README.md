## Description
Test-cases will run checksum against setup conf files, given exact input.
The purpose of this is to provide reproduceable output.

## Functions
* **Verify** actual output against expected output.
* **Checksum** file integrity.
* Set **file permissions** (example: user == root, chmod == 755).

## Test-cases
* Given a specific PCI list and pre-install setup (Hugepages, CPU isolation), verify
    * **Multi-boot** setup.
    * **Static** setup.
* Given a specific input device list and pre-install setup (Hugepages), verify an **Evdev** setup.