
# Guest Setup Guide
This document is a general overview and guide of installation, features, and optimizations of a QEMU/KVM guest/virtual machine (VM). You may also view example XML files of which you may use as a template.

## Table of Contents
- [Guest XML a](#guest-xml-layout)
- [Host Optimizations](#host-optimizations)
- [Guest Optimizations](#guest-optimizations)
- [Benchmarking Guest Performance](#benchmarking-guest-performance)
- [References](#references)

## Guest XML Layout
Below is an *incomplete* XML template for building a guest machine. The lines include additional features, of which are absent when creating a guest XML (with the `virsh` CLI command or `virt-manager` GUI application).

### Syntax
```xml
<parent_tag_name attribute_name="attribute_value">
  <child_tag_name>child_tag_value</child_tag_name>
</parent_tag_name>
```

### `<domain>`

| `<domain>` Tag     | Attribute    | Value                                          | Description                                        |
| ------------------ | ------------ | ---------------------------------------------- | -------------------------------------------------- |
|                    | `xmlns:qemu` | `"http://libvirt.org/schemas/domain/qemu/1.0"` | Enable QEMU [command lines](#qemu-command-line) and [overrides](#qemu-overrides).           |
|                    | `type`       | `"kvm"`                                        | Enable QEMU command lines and overrides.           |
| `<name/>`[<sup>1</sup>](#1-name-best-practice)          | none         | text                                           | Name of the Guest.                                 |
| `<memory/>`        | none         | a number                                       | Total allowed memory to guest, in Kilobytes.       |
| `<currentMemory/>` | none         | a number                                       | Currently allocated memory to guest, in Kilobytes. |

###### 1. `<name/>` Best practice:
**Note:** The following formatting examples are a personal preference of the Author.
Format: `purpose`**_**`vendor`\***_**`operating system`**_**`architecture`**_**`chipset`**_**`firmware`**_**`topology`

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
      - Does support legacy guests (example: Windows NT 5 and before, XP/2000, 9x).
      - PCI bus only; expansion devices will exist on a PCI topology.
      - Will accept PCIe devices.
    - Q35:&ensp;&ensp;&ensp;&nbsp;`q35`
      - Virtual, newer platform.
      - Native PCIe bus; expansion devices will exist on a PCIe topology.
      - Does not support legacy guests.
  - Firmware<sup>[ref](#firmware)</sup>:
    - BIOS:&ensp;`bios`
    - UEFI:&nbsp;&ensp;`uefi`
  - Short-hand of Core topology:&ensp;`4c8t`
    - Given the amount of physical cores (example: 4).
    - Given the amount of logical threads per core (2 * 4 = 8).

#### Memory

| `<memoryBacking>` Tag | Attribute | Value       | Description                                                       |
| --------------------- | --------- | ----------- | ----------------------------------------------------------------- |
| `<allocation/>`       | `mode`    | `immediate` | Specifies how memory allocation is performed.                     |
| `<discard/>`          | none      | none        | TODO: add here.                                                   |
| `<hugepages/>`[<sup>1</sup>](#1-hugepages)       | none      | none        | Enable Huge memory pages.                                         |
| `<nosharepages/>`     | none      | none        | Prevents the Host from merging the same memory used among guests. |

###### 1. `<hugepages/>`
- Static allocation of *Host* memory pages into *Guest* memory pages.
- Huge: Memory page size greater than 4K bytes (2M or 1G bytes). The greater the size, the lower the Host overhead.
- Dynamic *Host* memory page allocation is more flexible, but will require defragmentation before use as *Guest* memory pages (before a Guest machine may start).
- **Warning:** If the specified *Guest* memory pages exceeds the allocated *Host* memory pages, then the Guest machine will fail to start.

#### CPU topology (1/2)

| `<vcpu>` Tag | Attribute   | Value      | Description                                                     |
| ------------ | ----------- | ---------- | --------------------------------------------------------------- |
|              | parent      | a number   | Specify number of Host threads for Guest (same as `<cpu>` tag). |
|              | `placement` | `"static"` | Static allocation of Guest CPU threads.                         |

| `<iothreads>` Tag | Attribute | Value       | Description                                                                                  |
| ----------------- | --------- | ----------- | -------------------------------------------------------------------------------------------- |
|                   | none      | a number    | Specify number of Host threads to manage storage block devices (see as `<iothreadpin>` tag). |

| `<cputune>` Tag | Attribute  | Value       | Description                                  |
| --------------- | ---------- | ----------- | -------------------------------------------- |
| `<vcpupin>`     | `vcpu`     | a number    | Guest CPU: the Guest thread ID number.[<sup>1</sup>]      |
| `<vcpupin>`     | `cpuset`   | a number    | Guest CPU: the Host thread ID number.[<sup>2</sup>]      |
| `<emulatorpin>` | `cpuset`   | a number    | Guest IRQ: the Guest IO thread ID number.[<sup>3</sup>]  |
| `<iothreadpin>` | `iothread` | a number    | Guest IO: the Guest IO thread ID number.    |
| `<iothreadpin>` | `cpuset`   | a number    | Guest IO: the Host thread ID numbers.[<sup>4</sup>]      |

###### 1. `<vcpupin vcpu>`
- Count does not exceed value defined in `<vcpu placement>`.

###### 2. `<vcpupin cpuset>`
- Threads should not overlap Host process threads.

###### 3. `<emulatorpin cpuset>`
- Emulator threads handle Interrupt Requests for Guest hardware emulation.
- Threads should not overlap Guest CPU threads defined in `vcpupin cpuset`.

###### 4. `<iothreadpin cpuset>`
- IO threads handle IO processes for Guest virtual drives/disks.
- Threads should not overlap Guest CPU threads defined in `vcpupin cpuset`.

```xml
  <!-- CPU topology (1/2), given a 4-core, 8-thread CPU -->
  <vcpu placement="static">4</vcpu>           <!-- Specify number of Host threads for Guest (Copy this value from "cpu" tag). -->
  <iothreads>1</iothreads>                    <!-- Specify number of Host threads to manage storage block devices -->
  <cputune>
    <vcpupin vcpu="0" cpuset="2"/>            <!-- Guest CPU: Use the third core, first thread -->
    <vcpupin vcpu="1" cpuset="6"/>            <!-- Guest CPU: Use the third core, second thread -->
    <vcpupin vcpu="2" cpuset="3"/>            <!-- Guest CPU: Use the fourth core, first thread -->
    <vcpupin vcpu="3" cpuset="7"/>            <!-- Guest CPU: Use the fourth core, second thread -->

    <emulatorpin cpuset="1,4"/>               <!-- Guest IO: Use the second core, first thread -->
    <iothreadpin iothread="1" cpuset="1,4"/>  <!-- Guest IO: Use the second core, second thread -->
  </cputune>
```

#### System information spoofing
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
      <entry name="version">Default string</entry>              <!-- Leave this unchanged. -->
      <entry name="serial">Default string</entry>               <!-- Leave this unchanged. -->
      <entry name="sku">Default string</entry>                  <!-- Leave this unchanged. -->
      <entry name="family">Default string</entry>               <!-- Leave this unchanged. -->
    </system>
  </sysinfo>
```

#### Features
```xml
    <!-- Hyper-V: Enlightenments for Microsoft Windows guests only -->
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

#### CPU topology (2/2)
```xml
  <!-- CPU information and features -->
  <cpu mode="host-passthrough" check="none" migratable="on">  <!-- Spoof the CPU info, with the actual CPU info. -->
    <topology sockets="1" dies="1" cores="6" threads="2"/>    <!-- Set CPU topology (2/2). -->
    <cache mode="passthrough"/>                               <!--  -->
    <feature policy="disable" name="hypervisor"/>             <!--  -->
    <feature policy="disaFeatures" present="yes"/>       <!--  -->
    <timer name="tsc" present="yes" mode="native"/> <!--  -->
  </clock>
```

#### Power Management
```xml
  <!-- Power Management -->
  <pm>
    <suspend-to-mem enabled="yes"/>   <!-- Enable S3 Suspend (Sleep) -->
    <suspend-to-disk enabled="yes"/>  <!-- Enable S4 Suspend (Hibernation) -->
  </pm>
```

#### Devices
```xml
  <!-- Emulated, Paravirtual, Passed-through Real PCI/e, and Shared Memory devices -->
  <devices>
  ...
  </devices>
```

#### QEMU command line
```xml
  <qemu:commandline>...</qemu:commandline>  <!-- Add Evdev here -->
```

#### QEMU overrides
```xml
  <qemu:override>...</qemu:override>
```

## Host Optimizations

## Guest Optimizations

## Benchmarking Guest Performance

## References