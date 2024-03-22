
# Guest Setup Guide
This document is a general overview and guide of installation, features, and optimizations of a QEMU/KVM guest/virtual machine (VM). You may also view example XML files of which you may use as a template.

## Table of Contents
- [Guest XML Template](#guest-xml-template)
- [Host Optimizations](#host-optimizations)
- [Guest Optimizations](#guest-optimizations)
- [Benchmarking Guest Performance](#benchmarking-guest-performance)
- [References](#references)
- [Disclaimer](#disclaimer)

## Guest XML Template
Below is an *incomplete* XML template for building a guest machine. The lines include additional features, of which are absent when creating a guest XML (with the `virsh` CLI command or `virt-manager` GUI application).

```xml
<domain xmlns:qemu="http://libvirt.org/schemas/domain/qemu/1.0" type="kvm">     <!-- Add this line to allow for QEMU commandline and overrides-->

  <name>windows10_uefi</name>

  <!-- Memory -->
  <memory>...</memory>                <!-- Memory in KiB. Set in Virt-Manager -->
  <currentMemory>...</currentMemory>  <!-- Memory in KiB. Set in Virt-Manager -->

  <memoryBacking>
    <hugepages/>                      <!-- Enables Hugepages  -->
    <nosharepages/>                   <!--   -->
    <allocation mode="immediate"/>    <!--   -->
    <discard/>                        <!--   -->
  </memoryBacking>

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

  <!-- Features and Optimiziations -->
  <features>
    <acpi/>
    <apic/>

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

  <!-- CPU information and features -->
  <cpu mode="host-passthrough" check="none" migratable="on">  <!-- Spoof the CPU info, with the actual CPU info. -->
    <topology sockets="1" dies="1" cores="6" threads="2"/>    <!-- Set CPU topology (2/2). -->
    <cache mode="passthrough"/>                               <!--  -->
    <feature policy="disable" name="hypervisor"/>             <!--  -->
    <feature policy="disable" name="svm"/>                    <!--  -->
  </cpu>

<!-- Clock -->
  <clock offset="localtime">
    <timer name="rtc" tickpolicy="catchup"/>
    <timer name="pit" tickpolicy="delay"/>
    <timer name="hpet" present="no"/>
    <timer name="kvmclock" present="no"/>
    <timer name="hypervclock" present="yes"/>
    <timer name="tsc" present="yes" mode="native"/>
  </clock>

  <!-- Power Management -->
  <pm>
    <suspend-to-mem enabled="yes"/>   <!-- Enable S3 Suspend (Sleep) -->
    <suspend-to-disk enabled="yes"/>  <!-- Enable S4 Suspend (Hibernation) -->
  </pm>

  <!-- Emulated, Paravirtual, Passed-through Real PCI/e, and Shared Memory devices -->
  <devices>
  
  
  
  
  
  </devices>
  <qemu:commandline>...</qemu:commandline>  <!-- Add Evdev here -->
  <qemu:override>...</qemu:override>
</domain>
```

##

## Benchmarking Guest Performance

## References

## Disclaimer
The Author makes no guarantees of the stability, performance or success of the features, optimizations, and settings described in this document. The information detailed within should be applied and thoroughly tested before considering for a production environment.