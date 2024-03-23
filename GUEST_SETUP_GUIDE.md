
# Guest Setup Guide
## TODO:
- use collapsable dropdowns (https://gist.github.com/pierrejoubert73/902cc94d79424356a8d20be2b382e1ab).
- flesh out "Guest XML Layout".
- add Guest XML file with all lines referenced in "Guest XML Layout".
- add citations!
- begin work on "Host Optimizations".
- begin work on "Guest Optimizations".
- begin work on "Benchmarking Guest Performance".
- sort multiple related citations into "References".
- add pictures of virt-manager.
- how to setup virtio disks (virtio, virtio-scsi).

## Table of Contents
- [deploy-VFIO README](deploy-vfio-readme)
- [About](#about)
- [Guest XML Layout](#guest-xml-layout)
- [Host Optimizations](#host-optimizations)
- [Guest Optimizations](#guest-optimizations)
- [Benchmarking Guest Performance](#benchmarking-guest-performance)
- [References](#references)

## About
This document is a general overview and guide of installation, features, and optimizations of a QEMU/KVM Virtual Machine (VM) or Guest. Review the XML references below or view example XML files, of which you may use as a template.

## Guest XML Layout
Below is an *incomplete* layout for building a Guest machine. The lines include additional features, of which are absent when creating a Guest XML (with the `virsh` CLI command or `virt-manager` GUI application).

### Contents
- [Syntax](#syntax)
- [First lines in XML](#first-lines-in-xml)
- [Memory](#memory)
- [CPU topology (1/2)](#cpu-topology-12)
- [System information spoofing](#system-information-spoofing)
- [Features](#features)
- [CPU topology (2/2)](#cpu-topology-22)
- [Power Management](#power-management)
- [Devices](#devices)
- [QEMU command line](#qemu-overrides)
- [QEMU overrides](#qemu-overrides)

### Syntax
```xml
<parent_tag_name attribute_name="attribute_value">
  <child_tag_name>child_tag_value</child_tag_name>
</parent_tag_name>
```

### First lines in XML

| `<domain>` Tag     | Attribute    | Value                                          | Description                                        |
| ------------------ | ------------ | ---------------------------------------------- | -------------------------------------------------- |
|                    | `xmlns:qemu` | `"http://libvirt.org/schemas/domain/qemu/1.0"` | Enable QEMU [command lines](#qemu-command-line) and [overrides](#qemu-overrides).           |
|                    | `type`       | `"kvm"`                                        | Enable QEMU [command lines](#qemu-command-line) and [overrides](#qemu-overrides).           |
| `<name/>`[<sup>1</sup>](#1-name-best-practice)          | none         | text                                           | Name of the Guest.                                 |

###### 1. `<name/>` Best practice:
**Note:** The following formatting examples are a personal preference of the Author.

**Format:** `purpose`**_**`vendor`\***_**`operating system`**_**`architecture`**_**`chipset`**_**`firmware`**_**`topology`

**\*** Optional, if Host machine contains two (2) or more video devices (GPU/VGA).
  - Example systems and names:
    - Modern gaming machine:&ensp;&ensp;&ensp;&ensp;&ensp;`game_nvidia_win10_x64_q35_uefi_6c12t`
    - Older 2000s gaming machine:&ensp;`retro_amd_winxp_x86_i440fx_bios_2c4t`
    - Retro 1990s gaming machine:&ensp;`retro_3dfx_win98_x86_i440fx_bios_1c1t`
    - Intel MacOS workstation:&ensp;&ensp;&ensp;&ensp;&ensp;&nbsp;`work_macos_amd_x64_q35_uefi_6c12t`
  - Purpose of the Guest (and suggested names):
    - Gaming PC:&ensp;&ensp;&ensp;&ensp;&ensp;&ensp;`game`
    - Legacy/Retro PC:&ensp;`retro`
    - Server:&ensp;&ensp;&ensp;&ensp;&ensp;&ensp;&ensp;&ensp;&ensp;&ensp;&nbsp;`server`
    - Workstation PC:&ensp;&ensp;`work`
    - etc.
  - Vendor name of the Video device:
    - AMD:&ensp;&ensp;&ensp;&ensp;&ensp;`amd`
    - Intel:&ensp;&ensp;&ensp;&ensp;&ensp;`intel`
    - NVIDIA:&ensp;&ensp;&ensp;`nvidia`
    - emulated:&ensp;`emugpu`
    - non-mainstream or legacy:
      - 3DFX:&ensp;`3dfx`.
  - Short name of the Operating System (OS):
    - Apple Macintosh:&ensp;&ensp;&ensp;&nbsp;`macos`
    - Linux:&ensp;&ensp;&ensp;&ensp;&ensp;&ensp;&ensp;&ensp;&ensp;&ensp;&ensp;&ensp;&ensp;&ensp;`arch`, `debian`, `redhat`, `ubuntu`
    - Microsoft Windows:&ensp;`win98`, `winxp`, `win10`
    - etc.
  - Short name of the CPU architecture<sup>[ref](#cpu-architecture)</sup>:
    - AMD/Intel 32-bit:&ensp;`x86`
    - AMD/Intel 64-bit:&ensp;`x64`
    - ARM 32-bit:&ensp;&ensp;&ensp;&ensp;&ensp;&ensp;&nbsp;`aarch32`
    - ARM 64-bit:&ensp;&ensp;&ensp;&ensp;&ensp;&ensp;&nbsp;`aarch64`
    - etc.
  - Virtualized chipset<sup>[ref](#chipset)</sup>:
    - I440FX:&ensp;`i440fx`
      - Emulated, older chipset by Intel.
      - Does support legacy Guests (example: Windows NT 5 and before, XP/2000, 9x).
      - PCI bus only; expansion devices will exist on a PCI topology.
      - Will accept PCIe devices.
    - Q35:&ensp;&ensp;&ensp;&nbsp;`q35`
      - Virtual, newer platform.
      - Native PCIe bus; expansion devices will exist on a PCIe topology.
      - Does not support legacy Guests.
  - Firmware<sup>[ref](#firmware)</sup>:
    - BIOS:&ensp;`bios`
    - UEFI:&nbsp;&ensp;`uefi`
  - Short-hand of Core topology:&ensp;`4c8t`
    - Given the amount of physical cores (example: 4).
    - Given the amount of logical threads per core (2 * 4 = 8).

### Memory
To gather information of system memory, execute: `free --kibi --total --wide`

| `<memory>` Tag | Attribute | Value    | Description                                                       |
| -------------- | --------- | -------- | ----------------------------------------------------------------- |
|                | parent    | a number | The total amount of memory.                                       |
|                | `unit`    | `"KiB"`  | Amount of memory in Kibibytes (1024 bytes, Kilo is 1000 bytes).   |

| `<currentMemory>` Tag | Attribute | Value    | Description                                                       |
| --------------------- | --------- | -------- | ----------------------------------------------------------------- |
|                       | parent    | a number | The current amount of memory.                                     |
|                       | `unit`    | `"KiB"`  | Amount of memory in Kibibytes (1024 bytes, Kilo is 1000 bytes).   |

| `<memoryBacking>` Tag | Attribute | Value       | Description                                                       |
| --------------------- | --------- | ----------- | ----------------------------------------------------------------- |
| `<allocation/>`       | `mode`    | `immediate` | Specifies how memory allocation is performed.                     |
| `<discard/>`          | none      | none        | TODO: define, what is this?                                                   |
| `<hugepages/>`[<sup>1</sup>](#1-hugepages)       | none      | none        | Enable Huge memory pages.                                         |
| `<nosharepages/>`     | none      | none        | Prevents the Host from merging the same memory used among Guests. |

###### 1. `<hugepages/>`
- Static allocation of *Host* memory pages into *Guest* memory pages.
- **Huge:** Memory page size greater than 4K bytes (2M or 1G bytes). The greater the size, the lower the Host overhead.
- Dynamic *Host* memory page allocation is more flexible, but will require defragmentation before use as *Guest* memory pages (before a Guest machine may start).
- **Warning:** If the specified *Guest* memory pages exceeds the allocated *Host* memory pages, then the Guest machine will fail to start.

### CPU topology (1/2)
To gather information about your CPU, execute: `lscpu | grep --extended-regexp --ignore-case "per core|per socket|socket"`

| `<vcpu>` Tag | Attribute   | Value      | Description                                                     |
| ------------ | ----------- | ---------- | --------------------------------------------------------------- |
|              | parent      | a number   | Specify number of Host threads for Guest (same as `<cpu>` tag). |
|              | `placement` | `"static"` | Static allocation of Guest CPU threads.                         |

| `<iothreads>` Tag | Attribute | Value       | Description                                                                                  |
| ----------------- | --------- | ----------- | -------------------------------------------------------------------------------------------- |
|                   | none      | a number    | Specify number of Host threads to manage storage block devices (see as `<iothreadpin>` tag). |

| `<cputune>` Tag | Attribute  | Value       | Description                                  |
| --------------- | ---------- | ----------- | -------------------------------------------- |
| `<vcpupin>`     | `vcpu`     | a number    | Guest CPU: the Guest thread ID number.[<sup>1</sup>](#1-vcpupin-vcpu)      |
| `<vcpupin>`     | `cpuset`   | a number    | Guest CPU: the Host thread ID number.[<sup>2</sup>](#2-vcpupin-cpuset)      |
| `<emulatorpin>` | `cpuset`   | a number    | Guest IRQ: the Guest IO thread ID number.[<sup>3</sup>](#3-emulatorpin-cpuset)  |
| `<iothreadpin>` | `iothread` | a number    | Guest IO: the Guest IO thread ID number.    |
| `<iothreadpin>` | `cpuset`   | a number    | Guest IO: the Host thread ID numbers.[<sup>4</sup>](#4-iothreadpin-cpuset)      |

###### 1. `<vcpupin vcpu>`
- Count does not exceed value as defined in `<vcpu placement>`.

###### 2. `<vcpupin cpuset>`
- Threads should not overlap Host process threads.

###### 3. `<emulatorpin cpuset>`
- Emulator threads handle Interrupt Requests for Guest hardware emulation.
- Threads should not overlap Guest CPU threads as defined in `vcpupin cpuset`.

###### 4. `<iothreadpin cpuset>`
- IO threads handle IO processes for Guest virtual drives/disks.
- Threads should not overlap Guest CPU threads as defined in `vcpupin cpuset`.

##### Example XML:
```xml
  <!-- Given a 4-core, 8-thread CPU... -->
  <vcpu placement="static">4</vcpu>           <!-- Statically allocate four (4) cores to Guest. -->
  <iothreads>1</iothreads>                    <!-- Define one (1) thread to IO. -->
  <cputune>
    <vcpupin vcpu="0" cpuset="2"/>            <!-- Guest CPU: use the third core, first thread. -->
    <vcpupin vcpu="1" cpuset="6"/>            <!-- Guest CPU: use the third core, second thread. -->
    <vcpupin vcpu="2" cpuset="3"/>            <!-- Guest CPU: use the fourth core, first thread. -->
    <vcpupin vcpu="3" cpuset="7"/>            <!-- Guest CPU: use the fourth core, second thread. -->
    <emulatorpin cpuset="1,4"/>               <!-- Guest IRQ: use the second core, two threads. -->
    <iothreadpin iothread="1" cpuset="1,4"/>  <!-- Guest IO: use the second core, two threads. -->
  </cputune>
```

### System information spoofing
To gather information about your BIOS, execute:

&ensp;`sudo dmidecode --type bios | grep --extended-regexp --ignore-case "vendor|version|release date"`

To gather information about your system, execute:

&ensp;`sudo dmidecode --type system | grep --extended-regexp --ignore-case "manufacturer|product name|version|serial number|sku number|family"`

```xml
  <!-- BIOS and System spoofing (you may copy your actual info). -->
  <sysinfo type="smbios">                                       <!-- This line is necessary! -->
    <bios>
      <entry name="vendor">American Megatrends Inc.</entry>     <!-- AMI is the industry standard BIOS vendor. -->
      <entry name="version">version_of_bios_firmware</entry>
      <entry name="date">MM/DD/YYYY</entry>
    </bios>
    <system>
      <entry name="manufacturer">vendor_of_motherboard</entry>
      <entry name="product">product_name</entry>
      <entry name="version">Default string</entry>
      <entry name="serial">Default string</entry>
      <entry name="sku">Default string</entry>
      <entry name="family">Default string</entry>
    </system>
  </sysinfo>
```

### Features

TODO: make the following inline XML into chart, describe each feature.

```xml
    <hyperv mode="custom">
      <relaxed state="on"/>
      <vapic state="on"/>
      <spinlocks state="on" retries="8191"/>
      <vpindex state="on"/>
      <runtime state="on"/>
      <synic state="on"/>

      <stimer state="on">
        <direct state="on"/>
      </stimer>

      <reset state="on"/>
      <vendor_id state="on" value="1234567890ab"/>
      <frequencies state="on"/>
      <reenlightenment state="on"/>
      <tlbflush state="on"/>
      <ipi state="on"/>
      <evmcs state="on"/>
    </hyperv>
    <kvm>
      <hidden state="on"/>
    </kvm>
    <vmport state="off"/>
    <ioapic driver="kvm"/>
  </features>
```

### CPU topology (2/2)
To gather information about your CPU, execute: `lscpu | grep --extended-regexp --ignore-case "per core|per socket|socket"`

##### Example output:
```
Thread(s) per core:                 2
Core(s) per socket:                 8
Socket(s):                          1
```

TODO: make the following inline XML into chart, describe each feature.

```xml
  <cpu mode="host-passthrough" check="none" migratable="on">  <!-- Spoof the CPU info, with the actual CPU info. -->
    <topology sockets="1" dies="1" cores="6" threads="2"/>
    <cache mode="passthrough"/>
    <feature policy="disable" name="hypervisor"/>
    <feature policy="disable" present="yes"/>
    <timer name="tsc" present="yes" mode="native"/>
  </clock>
```

| `<cpu>` Tag  | Attribute    | Value                | Description                                                     |
| ------------ | ------------ | -------------------- | --------------------------------------------------------------  |
| parent       | `mode`       | `"host-passthrough"` | Spoof the Guest CPU info, with the actual Host CPU info.        |
|              | `check`      | `"none"`             | TODO: add here.                                                 |
|              | `migratable` | `"on"`               | TODO: add here.                                                 |
| `<topology>` | `sockets`    | a number             | The number of CPU sockets, or maxmium number of dies.           |
|              | `dies`       | a number             | The number of CPU dies (typically one).                         |
|              | `cores`      | a number             | The number of CPU cores.                                        |
|              | `threads`    | a number             | The number of CPU threads per core (typically a factor of two). |
| `<cache>`    | `mode`       | `"passthrough"`      | Passthrough the Host CPU cache.                                 |
| `<feature>`  | `policy`     | `"disable"`          | Disables policy.                                                |
|              | `name`       | `"hypervisor"`       | TODO: add here.                                                 |
| `<feature>`  | `policy`     | `"disable"`          | Disables policy.                                                |
|              | `present`    | `"yes"`              | TODO: add here.                                                 |
| `<timer>`    | `name`       | `"tsc"`              | TODO: add here.                                                 |
|              | `present`    | `"yes"`              | TODO: add here.                                                 |
|              | `mode`       | `"native"`           | TODO: add here.                                                 |

### Power Management
```xml
  <!-- Power Management -->
  <pm>
    <suspend-to-mem enabled="yes"/>   <!-- Enable S3 Suspend (Sleep) -->
    <suspend-to-disk enabled="yes"/>  <!-- Enable S4 Suspend (Hibernation) -->
  </pm>
```

### Devices

TODO: make the following inline XML into chart, describe each feature???
```xml
  <!-- Emulated, Paravirtual, Passed-through Real PCI/e, and Shared Memory devices -->
  <devices>
  ...
  </devices>
```

#### Emulated

TODO: make this inline XML?
- QEMU
- RedHat
- Other legacy devices
  - SoftGPU https://github.com/JHRobotics/softgpu

lorem ipsum

#### Real/Passthrough
TODO: make this inline XML?

  - AMD
    - Integrated
    - Dedicated
    - Reset bug
  - Intel
    - Integrated
    - Dedicated
      - **Note:** Not much research done regarding this topic. Please refer to any mentioned guides, the Reddit forum, or use an Internet search engine with the keywords `intel gpu vfio`.
  - NVIDIA
    - Problems:
      - Boot bug (Solution: Use known-good copy of given GPU's video BIOS or VBIOS).
      - TODO: add references, programs used, instructions, and XML here.

#### Memory devices

TODO: make this inline XML?
  - Looking Glass
  - Scream
  - ???

### QEMU command line

TODO: make the following inline XML into chart, describe each feature.
  - Evdev

```xml
  <qemu:commandline>...</qemu:commandline>  <!-- Add Evdev here -->
```

### QEMU overrides

TODO: make the following inline XML into chart, describe each feature.

```xml
  <qemu:override>...</qemu:override>
```

## Host Optimizations
TODO: add here.

## Guest Optimizations
TODO: add here.

## Benchmarking Guest Performance
TODO: add here.

## References
#### Chipset
&ensp;<sub>I440FX | **[Wikipedia](https://en.wikipedia.org/wiki/Intel_440FX)**</sub>

&ensp;<sub>I440FX | **[QEMU documentation](https://www.qemu.org/docs/master/system/i386/pc.html)**</sub>

&ensp;<sub>PCI vs PCIe | **[RedHat documentation](https://wiki.qemu.org/images/f/f6/PCIvsPCIe.pdf)**</sub>

&ensp;<sub>Q35 | **[RedHat documentation](https://wiki.qemu.org/images/4/4e/Q35.pdf)**</sub>

#### CPU architecture
&ensp;<sub>AArch32 | **[Wikipedia](https://en.wikipedia.org/wiki/ARM_architecture_family#AArch32)**</sub>

&ensp;<sub>AArch64 | **[Wikipedia](https://en.wikipedia.org/wiki/AArch64)**</sub>

&ensp;<sub>x86 | **[Wikipedia](https://en.wikipedia.org/wiki/X86)**</sub>

&ensp;<sub>x64 | **[Wikipedia](https://en.wikipedia.org/wiki/X64)**</sub>

#### Firmware
&ensp;<sub>BIOS | **[Wikipedia](https://en.wikipedia.org/wiki/BIOS)**</sub>

&ensp;<sub>UEFI | **[Wikipedia](https://en.wikipedia.org/wiki/UEFI)**</sub>

### Memory backing
&ensp;<sub>Memory Tuning on Virtual Machines | **[RedHat documentation](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/virtualization_tuning_and_optimization_guide/sect-virtualization_tuning_optimization_guide-memory-tuning)**</sub>

#### Hugepages
&ensp;<sub>Huge memory pages | **[Arch Wiki](https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF#Huge_memory_pages)**</sub>

&ensp;<sub>Huge pages | **[Debian Wiki](https://wiki.debian.org/Hugepages)**</sub>