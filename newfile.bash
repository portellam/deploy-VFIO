#!/bin/bash sh
exit 0



# detect total cpu cores, if 4 core plus, subtract two cores for host. if hyperthreaded, add hyperthreads as vcpus following each core vcpu
# set iothreads



#
declare -a arr_XML_hugepages=(
"        <hugepages/>
        <nosharepages/>
        <allocation mode="immediate"/>
        <discard/>")

declare -a arr_XML=(
"<domain xmlns:qemu="http://libvirt.org/schemas/domain/qemu/1.0" type="kvm">
    <name>$str_newMachineName</name>
    <uuid>7137e531-2a2b-4478-841a-2449d66b324f</uuid>
    <title>$str_newMachineName</title>
    <metadata>
        <libosinfo:libosinfo xmlns:libosinfo="http://libosinfo.org/xmlns/libvirt/domain/1.0">
            <libosinfo:os id="http://microsoft.com/win/10"/>
        </libosinfo:libosinfo>
    </metadata>
    <memory unit="KiB">$int_machineMem</memory>
    <currentMemory unit="KiB">$int_machineMem</currentMemory>
    <memoryBacking>
$arr_XML_hugepages
    </memoryBacking>
    # for loop, find first and last ints of cores and smt threads #
    <vcpu placement="static" cpuset="2-7,10-15">$int_vThread</vcpu> # for 4-core+ (4c/8t or 4c/4t) CPUs, use at most all but 2-cores.
    <iothreads>2</iothreads>                                                            # for 2-core systems, use at most 1-core
    <iothreadids>
        <iothread id="1"/>
        <iothread id="2"/>
    </iothreadids>
    <cputune>
    # for loop, find all cores and smt threads #
        <vcpupin vcpu="0" cpuset="2"/>            # order VCPUs by multi-threads, if available (core and it's second thread)
        <vcpupin vcpu="1" cpuset="10"/>         #
        <vcpupin vcpu="2" cpuset="3"/>
        <vcpupin vcpu="3" cpuset="11"/>
        <vcpupin vcpu="4" cpuset="4"/>
        <vcpupin vcpu="5" cpuset="12"/>
        <vcpupin vcpu="6" cpuset="5"/>
        <vcpupin vcpu="7" cpuset="13"/>
        <vcpupin vcpu="8" cpuset="6"/>
        <vcpupin vcpu="9" cpuset="14"/>
        <vcpupin vcpu="10" cpuset="7"/>
        <vcpupin vcpu="11" cpuset="15"/>
        
        <emulatorpin cpuset="1,9"/>
        <iothreadpin iothread="1" cpuset="1"/>
        <iothreadpin iothread="2" cpuset="9"/>
    </cputune>
    <resource>
        <partition>/machine</partition>
    </resource>
    <os>
        <type arch="x86_64" machine="pc-q35-5.2">hvm</type>
        <loader readonly="yes" type="pflash">/usr/share/OVMF/OVMF_CODE_4M.fd</loader>
        <nvram>/var/lib/libvirt/qemu/nvram/$str_newMachineName_VARS.fd</nvram>
        <boot dev="hd"/>
        <bootmenu enable="no"/>
    </os>
    <features>
        <acpi/>
        <apic/>
        <hyperv>
            <relaxed state="on"/>
            <vapic state="on"/>
            <spinlocks state="on" retries="8191"/>
            <vpindex state="on"/>
            <runtime state="on"/>
            <synic state="on"/>
            <stimer state="on"/>
            <reset state="on"/>
            <vendor_id state="on" value="1234567890ab"/>
            <frequencies state="on"/>
        </hyperv>
        <kvm>
            <hidden state="on"/>
        </kvm>
        <vmport state="off"/>
        <ioapic driver="kvm"/>
    </features>
    <cpu mode="host-passthrough" check="none" migratable="on">
        <topology sockets="$int_hostSocket" dies="1" cores="$int_vCore" threads="$int_vThread"/>
        <cache mode="passthrough"/>
    </cpu>
    <clock offset="utc">                                                                                          
        <timer name="rtc" tickpolicy="catchup"/>
        <timer name="pit" tickpolicy="delay"/>
        <timer name="hpet" present="no"/>
        <timer name="kvmclock" present="no"/>
        <timer name="hypervclock" present="yes"/>
        <timer name="tsc" present="yes" mode="native"/>
    </clock>
    <on_poweroff>destroy</on_poweroff>
    <on_reboot>restart</on_reboot>
    <on_crash>destroy</on_crash>
    <pm>
        <suspend-to-mem enabled="yes"/>
        <suspend-to-disk enabled="yes"/>
    </pm>
    <devices>
        <emulator>/usr/bin/qemu-system-x86_64</emulator>
        <controller type="usb" index="0" model="qemu-xhci" ports="15">
            <address type="pci" domain="0x0000" bus="0x02" slot="0x00" function="0x0"/>
        </controller>
        <controller type="sata" index="0">
            <address type="pci" domain="0x0000" bus="0x00" slot="0x1f" function="0x2"/>
        </controller>
        <controller type="pci" index="0" model="pcie-root"/>
        <controller type="pci" index="1" model="pcie-root-port">
            <model name="pcie-root-port"/>
            <target chassis="1" port="0x10"/>
            <address type="pci" domain="0x0000" bus="0x00" slot="0x02" function="0x0" multifunction="on"/>
        </controller>
        <controller type="pci" index="2" model="pcie-root-port">
            <model name="pcie-root-port"/>
            <target chassis="2" port="0x11"/>
            <address type="pci" domain="0x0000" bus="0x00" slot="0x02" function="0x1"/>
        </controller>
        <controller type="pci" index="3" model="pcie-root-port">
            <model name="pcie-root-port"/>
            <target chassis="3" port="0x12"/>
            <address type="pci" domain="0x0000" bus="0x00" slot="0x02" function="0x2"/>
        </controller>
        <controller type="pci" index="4" model="pcie-root-port">
            <model name="pcie-root-port"/>
            <target chassis="4" port="0x13"/>
            <address type="pci" domain="0x0000" bus="0x00" slot="0x02" function="0x3"/>
        </controller>
        <controller type="pci" index="5" model="pcie-root-port">
            <model name="pcie-root-port"/>
            <target chassis="5" port="0x14"/>
            <address type="pci" domain="0x0000" bus="0x00" slot="0x02" function="0x4"/>
        </controller>
        <controller type="pci" index="6" model="pcie-root-port">
            <model name="pcie-root-port"/>
            <target chassis="6" port="0x15"/>
            <address type="pci" domain="0x0000" bus="0x00" slot="0x02" function="0x5"/>
        </controller>
        <controller type="pci" index="7" model="pcie-to-pci-bridge">
            <model name="pcie-pci-bridge"/>
            <address type="pci" domain="0x0000" bus="0x03" slot="0x00" function="0x0"/>
        </controller>
        <controller type="pci" index="8" model="pci-bridge">
            <model name="pci-bridge"/>
            <target chassisNr="8"/>
            <address type="pci" domain="0x0000" bus="0x07" slot="0x01" function="0x0"/>
        </controller>
        <controller type="pci" index="9" model="pci-bridge">
            <model name="pci-bridge"/>
            <target chassisNr="9"/>
            <address type="pci" domain="0x0000" bus="0x07" slot="0x02" function="0x0"/>
        </controller>
        <controller type="pci" index="10" model="pci-bridge">
            <model name="pci-bridge"/>
            <target chassisNr="10"/>
            <address type="pci" domain="0x0000" bus="0x07" slot="0x03" function="0x0"/>
        </controller>
        <controller type="pci" index="11" model="pci-bridge">
            <model name="pci-bridge"/>
            <target chassisNr="11"/>
            <address type="pci" domain="0x0000" bus="0x07" slot="0x04" function="0x0"/>
        </controller>
        <controller type="pci" index="12" model="pci-bridge">
            <model name="pci-bridge"/>
            <target chassisNr="12"/>
            <address type="pci" domain="0x0000" bus="0x07" slot="0x05" function="0x0"/>
        </controller>
        <controller type="pci" index="13" model="pcie-root-port">
            <model name="pcie-root-port"/>
            <target chassis="13" port="0x16"/>
            <address type="pci" domain="0x0000" bus="0x00" slot="0x02" function="0x6"/>
        </controller>
        <controller type="pci" index="14" model="pcie-root-port">
            <model name="pcie-root-port"/>
            <target chassis="14" port="0x17"/>
            <address type="pci" domain="0x0000" bus="0x00" slot="0x02" function="0x7"/>
        </controller>
        <controller type="pci" index="15" model="pcie-root-port">
            <model name="pcie-root-port"/>
            <target chassis="15" port="0x18"/>
            <address type="pci" domain="0x0000" bus="0x00" slot="0x03" function="0x0" multifunction="on"/>
        </controller>
        <controller type="pci" index="16" model="pcie-root-port">
            <model name="pcie-root-port"/>
            <target chassis="16" port="0x19"/>
            <address type="pci" domain="0x0000" bus="0x00" slot="0x03" function="0x1"/>
        </controller>
        <controller type="pci" index="17" model="pcie-root-port">
            <model name="pcie-root-port"/>
            <target chassis="17" port="0x1a"/>
            <address type="pci" domain="0x0000" bus="0x00" slot="0x03" function="0x2"/>
        </controller>
        <controller type="pci" index="18" model="pcie-root-port">
            <model name="pcie-root-port"/>
            <target chassis="18" port="0x1b"/>
            <address type="pci" domain="0x0000" bus="0x00" slot="0x03" function="0x3"/>
        </controller>
        <controller type="pci" index="19" model="pcie-root-port">
            <model name="pcie-root-port"/>
            <target chassis="19" port="0x8"/>
            <address type="pci" domain="0x0000" bus="0x00" slot="0x01" function="0x0" multifunction="on"/>
        </controller>
        <controller type="pci" index="20" model="pcie-root-port">
            <model name="pcie-root-port"/>
            <target chassis="20" port="0x9"/>
            <address type="pci" domain="0x0000" bus="0x00" slot="0x01" function="0x1"/>
        </controller>
        <controller type="pci" index="21" model="pcie-root-port">
            <model name="pcie-root-port"/>
            <target chassis="21" port="0xa"/>
            <address type="pci" domain="0x0000" bus="0x00" slot="0x01" function="0x2"/>
        </controller>
        <controller type="pci" index="22" model="pcie-root-port">
            <model name="pcie-root-port"/>
            <target chassis="22" port="0xb"/>
            <address type="pci" domain="0x0000" bus="0x00" slot="0x01" function="0x3"/>
        </controller>
        <controller type="scsi" index="0" model="virtio-scsi">
            <address type="pci" domain="0x0000" bus="0x12" slot="0x00" function="0x0"/>
        </controller>
        <interface type="network">
            <mac address="52:54:00:e1:8a:73"/>
            <source network="default"/>
            <model type="virtio"/>
            <link state="up"/>
            <address type="pci" domain="0x0000" bus="0x01" slot="0x00" function="0x0"/>
        </interface>
        <input type="mouse" bus="ps2"/>
        <input type="keyboard" bus="ps2"/>
        <input type="keyboard" bus="virtio">
            <address type="pci" domain="0x0000" bus="0x04" slot="0x00" function="0x0"/>
        </input>
        <input type="mouse" bus="virtio">
            <address type="pci" domain="0x0000" bus="0x05" slot="0x00" function="0x0"/>
        </input>
        <hostdev mode="subsystem" type="pci" managed="yes">                                                         # GPU passthrough
            <driver name="vfio"/> 
            <source>
                <address domain="0x0000" bus="0x01" slot="0x00" function="0x0"/>
            </source>
            <rom file="/usr/share/vgabios/GP104.GA.GTX1070.8192.VFIO.211117.rom"/>                # NVIDIA card, so you need to grab an untainted VBIOS, and apply patches using a hex editor
            <address type="pci" domain="0x0000" bus="0x0d" slot="0x00" function="0x0"/> 
        </hostdev>                                                                                                                                            # my OS boot GPU can be toggled thru different GRUB menu entries and my script 'portellam/Auto-Xorg'
        <hostdev mode="subsystem" type="pci" managed="yes">
            <source>
                <address domain="0x0000" bus="0x01" slot="0x00" function="0x1"/>
            </source>
            <address type="pci" domain="0x0000" bus="0x0e" slot="0x00" function="0x0"/>
        </hostdev>
        <hostdev mode="subsystem" type="pci" managed="yes">
            <source>
                <address domain="0x0000" bus="0x02" slot="0x00" function="0x0"/>
            </source>
            <address type="pci" domain="0x0000" bus="0x0f" slot="0x00" function="0x0"/>
        </hostdev>
        <hostdev mode="subsystem" type="pci" managed="yes">
            <source>
                <address domain="0x0000" bus="0x06" slot="0x00" function="0x0"/>
            </source>
            <address type="pci" domain="0x0000" bus="0x10" slot="0x00" function="0x0"/>
        </hostdev>
        <hostdev mode="subsystem" type="pci" managed="yes">
            <source>
                <address domain="0x0000" bus="0x07" slot="0x00" function="0x0"/>
            </source>
            <address type="pci" domain="0x0000" bus="0x11" slot="0x00" function="0x0"/>
        </hostdev>
        <hostdev mode="subsystem" type="pci" managed="yes">
            <source>
                <address domain="0x0000" bus="0x08" slot="0x00" function="0x0"/>
            </source>
            <address type="pci" domain="0x0000" bus="0x15" slot="0x00" function="0x0"/>
        </hostdev>
        <memballoon model="virtio">
            <address type="pci" domain="0x0000" bus="0x06" slot="0x00" function="0x0"/>
        </memballoon>
        <shmem name="looking-glass">                                # looking-glass is a server program (on guest) framebuffer copy from guest GPU to a window on Linux host (windows supported only).
            <model type="ivshmem-plain"/>
            <size unit="M">64</size>
            <address type="pci" domain="0x0000" bus="0x0b" slot="0x01" function="0x0"/>
        </shmem>
        <shmem name="scream-ivshmem">                             # scream is a virtual audio cable server (on guest) to route audio from guest VM to Linux host.
            <model type="ivshmem-plain"/>                         # I prefer to use sound card Line-out to host audio Line-in, OR audio out on guest GPU
            <size unit="M">2</size>
            <address type="pci" domain="0x0000" bus="0x0c" slot="0x07" function="0x0"/>
        </shmem>
    </devices>
    <seclabel type="dynamic" model="dac" relabel="yes"/>
    <qemu:commandline>
        <qemu:arg value="-vga"/>                                                # good settings
        <qemu:arg value="none"/>
        <qemu:arg value="-set"/>
        <qemu:arg value="device.hostdev0.x-vga=on"/>        # hard set guest boot GPU to first virtual PCI slot (ex: my GPU)
        <qemu:arg value="-overcommit"/>
        <qemu:arg value="cpu-pm=on"/>
        <qemu:arg value="-object"/>                                         # auto-generated EVDEV by 'portellam/VFIO-script' function '00_evdev.bash', grab your configs from terminal and '/etc/libvirt/qemu.conf'
        <qemu:arg value="input-linux,id=kbd1,evdev=/dev/input/by-id/usb-0d3d_USBPS2-event-if01,grab_all=on,repeat=on"/>
        <qemu:arg value="-object"/>
        <qemu:arg value="input-linux,id=kbd2,evdev=/dev/input/by-id/usb-0d3d_USBPS2-event-kbd,grab_all=on,repeat=on"/>
        <qemu:arg value="-object"/>
        <qemu:arg value="input-linux,id=mouse1,evdev=/dev/input/by-id/usb-Logitech_G_Pro_Wireless_Gaming_Mouse_56C4DE9FC0D9C37C-event-mouse"/>
        <qemu:arg value="-object"/>
        <qemu:arg value="input-linux,id=kbd3,evdev=/dev/input/by-id/usb-Logitech_G_Pro_Wireless_Gaming_Mouse_56C4DE9FC0D9C37C-if01-event-kbd,grab_all=on,repeat=on"/>
    </qemu:commandline>
</domain>")
#