# Guest Machine Setup Guide
This document is a general overview and guide of installation, features, and optimizations of a QEMU/KVM guest/virtual machine (VM). You may also view example XML files of which you may use as a template.

# TODO
- Purpose: post vfio setup configuration and guest machine optimization.
- highlight optimizations?
- cite as much as reasonably possible.
- reference other useful projects (example: Evdev).
- xml file path.
- pictures of virt-manager.
- how to setup virtio disks (virtio, virtio-scsi).

## Guest XML file layout
```xml
<domain>
  <name>...</name>

  <memory>...</memory>
  <currentMemory>...</currentMemory>
  <memoryBacking>...</memoryBacking>        <!-- Add Hugepages here -->

  <vcpu>...</vcpu>                          <!-- Allocate Host CPU threads -->
  <iothreads>...</iothreads>                <!-- Specify what Host threads manage storage block devices -->
  <cputune>...</cputune>                    <!-- Specify what Host threads are virtual threads -->

  <sysinfo>
    <bios>...</bios>                        <!-- Spoof BIOS information -->
    <system>...</system>                    <!-- Spoof system information -->
  </sysinfo>

  <features>
    <hyperv>...</hyperv>                    <!-- Enlightenments for Microsoft Windows only -->
    <kvm>...</kvm>
  </features>

  <cpu>...</cpu>
  <clock>...</clock>
  <pm>...</pm>                              <!-- Power Management -->

  <devices>...</devices>                    <!-- Emulated, Paravirtual, Real PCI/e, and Shared Memory devices -->
  <qemu:commandline>...</qemu:commandline>  <!-- Add Evdev here -->
  <qemu:override>...</qemu:override>
</domain>
```
## Guest XML file Table of Contents (NOTE: is this necessary?)
* [domain](#domain)
* [name](#naming-the-guest)
* [memory](#memory)
* [currentMemory](#current-memory)
* [memoryBacking](#memory-backing)
* [vcpu](#vcpu)
* [iothreads](#io-threads)
* [cputune](#cpu-tuning)
* [sysinfo](#system-information)
* [features](#features)
* [cpu](#cpu)
* [clock](#clock)
* [pm](#power-management)
* [devices](#devices)
* [qemu](#qemu-commandline-and-overrides)
## `<domain>`
### `<name>`
#### Naming the Guest
The following formatting examples are a personal preference of the [Author](https://github.com/portellam).
  - Format: `<purpose>_<vendor*>_<operating-system>_<architecture>_<chipset>_<firmware>_<topology>`

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

### <memory>
lorem ipsum
#### <memory>
lorem ipsum
#### Memory Backing (TODO: explain all possible feature settings, and recommended use)
Features which influence behavior of how Host memory is allocated and used by Guest machines.
  - Example XML:
```xml
  <memoryBacking>
    <allocation mode="immediate"/>
    <discard/>
    <hugepages/>
    <nosharepages/>
  </memoryBacking>
```
  - `<memoryBacking>`<sup>[ref](#memory-backing)</sup>
    - `<allocation mode="">` specifies how memory allocation is performed.
      - `mode=immediate` dictates immediate allocation into Guest memory.
    - `<discard>` ? (TODO: determine the function of this feature)
    - `<hugepages` uses huge memory pages.<sup>[ref](#huge-pages)</sup>
        - Static allocation of into *Guest* huge pages.
        - Huge: Memory page size greater than 4K bytes (2M or 1G bytes). The greater the size, the lower the Host overhead.
        - Dynamic *Host* memory page allocation is more flexible, but will require defragmentation before use as *Guest* memory pages (before a Guest machine may start).
        - **Warning:** If the specified *Guest* memory pages exceeds the allocated *Host* memory pages, then the Guest machine will fail to start.
    - `<nosharepages>` prevents the host from merging the same memory used among guests.
### vCPU
lorem ipsum
### IO threads
### CPU tuning
lorem ipsum
### System information
lorem ipsum
### Features
lorem ipsum
#### Hyper-V enlightenments (for Microsoft Windows guests)
lorem ipsum
#### KVM features
lorem ipsum
### CPU
lorem ipsum
### Clock
lorem ipsum
### Power management
lorem ipsum
### Devices
lorem ipsum
#### Emulated
- QEMU
- RedHat
- Other legacy devices
  - SoftGPU https://github.com/JHRobotics/softgpu

lorem ipsum
#### Real/Passthrough
  - AMD
    - Integrated
    - Dedicated
    - Reset bug
      - 
  - Intel
    - Integrated
    - Dedicated
      - **Note:** Not much research done regarding this topic. Please refer to any mentioned guides, the Reddit forum, or use an Internet search engine with the keywords `intel gpu vfio`.
  - NVIDIA
    - Problems:
      - Boot bug (Solution: Use known-good copy of given GPU's video BIOS or VBIOS).
      - TODO: add references, programs used, instructions, and XML here.

#### Memory devices
  - Looking Glass
  - Scream
  - ???
#### QEMU commandline and overrides
  * Evdev
  * ???
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


