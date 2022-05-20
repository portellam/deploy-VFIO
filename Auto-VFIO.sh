#!/bin/bash

########## README ##########

# Maintainer:   github/portellam
# TL;DR:        Generates a VFIO passthrough setup (Multi-Boot or Static).

# TODO:
#   MultiBootSetup; menu entry
#   StaticSetup
#   hint/prompt user to install/execute Auto-Xorg.
#   setup input parameter passthrough
#   Virtual audio, Scream?
#   if VFIO setup already, suggest wipe of existing MultiBoot and/or StaticBoot
#

########## functions ##########

##### Prompts #####
function Prompts {

    # call functions #
    Evdev                                   # 1
    HugePages $str_GRUB_CMDLINE_Hugepages   # 2
    ZRAM                                    # 3
    ParsePCI $bool_VFIO_Setup
    #

    # prompt #
    str_input1=""               # reset input
    declare -i int_count=0      # reset counter

    str_prompt="$0: Setup VFIO by 'Multi-Boot' or Statically?\n\tMulti-Boot Setup includes adding GRUB boot options, each with one specific omitted VGA device.\n\tStatic Setup modifies '/etc/initramfs-tools/modules', '/etc/modules', and '/etc/modprobe.d/*.\n\tMulti-boot is the more flexible choice."

    if [[ -z $str_input1 ]]; then
        echo -e $str_prompt
    fi

    while true; do

        if [[ $int_count -ge 3 ]]; then
            echo "$0: Exceeded max attempts."
            str_input1="N"                   # default selection
            break
        else
            echo -en "$0: Setup VFIO? [ (M)ulti-Boot / (S)tatic / (N)one ]: "
            read -r str_input1
            str_input1=`echo $str_input1 | tr '[:lower:]' '[:upper:]'`
        fi

        case $str_input1 in

            "M")
                echo -e "$0: Continuing with Multi-Boot setup...\n"

                MultiBootSetup $bool_isVFIOsetup$str_GRUB_CMDLINE_Hugepages $arr_PCI_BusID $arr_PCIHWID $arr_PCIDriver $arr_PCIIndex $arr_PCIInfo $arr_VGABusID $arr_VGADriver $arr_VGAHWID

                StaticSetup $bool_isVFIOsetup$str_GRUB_CMDLINE_Hugepages $arr_PCI_BusID $arr_PCIHWID $arr_PCIDriver $arr_PCIIndex $arr_PCIInfo $arr_VGABusID $arr_VGADriver $arr_VGAHWID

                sudo update-grub                    # update GRUB
                sudo update-initramfs -u -k all     # update INITRAMFS

                echo -e "$0: NOTE: Review changes in:\n\t'/etc/default/grub'\n\t'/etc/initramfs-tools/modules'\n\t'/etc/modules'\n\t/etc/modprobe.d/*"
                break;;

            "S")
                echo -e "$0: Continuing with Static setup...\n"

                StaticSetup $bool_isVFIOsetup$str_GRUB_CMDLINE_Hugepages $arr_PCI_BusID $arr_PCIHWID $arr_PCIDriver $arr_PCIIndex $arr_PCIInfo $arr_VGABusID $arr_VGADriver $arr_VGAHWID

                sudo update-grub                    # update GRUB
                sudo update-initramfs -u -k all     # update INITRAMFS

                echo -e "$0: NOTE: Review changes in:\n\t'/etc/default/grub'\n\t'/etc/initramfs-tools/modules'\n\t'/etc/modules'\n\t/etc/modprobe.d/*"
                break;;

            "N")
                echo -e "$0: Skipping...\n";;
                exit 0

            *)
                echo "$0: Invalid input.";;

        esac
        ((int_count++))     # increment counter

    done
    #

}
##### end Prompts #####

##### Evdev #####
function Evdev {

    # parameters #
    str_file1="/etc/libvirt/qemu.conf"
    #

    # prompt #
    str_input1=""               # reset input
    declare -i int_count=0      # reset counter
    
    str_prompt="$0: Evdev (Event Devices) is a method that assigns input devices to a Virtual KVM (Keyboard-Video-Mouse) switch.\n\tEvdev is recommended for setups without an external KVM switch and multiple USB controllers.\n\tNOTE: View '/etc/libvirt/qemu.conf' to review changes, and append to a Virtual machine's configuration file."

    echo -e $str_prompt

    while [[ $str_input1 != "Y" && $str_input1 != "Z" && $str_input1 != "N" ]]; do

        if [[ $int_count -ge 3 ]]; then
            echo "$0: Exceeded max attempts."
            str_input1="N"                   # default selection
        else
            echo -en "$0: Setup Evdev? [ Y/n ]: "
            read -r str_input1
            str_input1=`echo $str_input1 | tr '[:lower:]' '[:upper:]'`
        fi

        case $str_input1 in

            "Y"|"E")
                #echo -e "$0: Continuing...\n"
                break;;

            "N")
                echo -e "$0: Skipping...\n"
                return 0;;

            *)
                echo "$0: Invalid input.";;

        esac
        ((int_count++))     # increment counter

    done
    #

    # find first normal user
    str_UID1000=`cat /etc/passwd | grep 1000 | cut -d ":" -f 1`
    #

    # add to group
    declare -a arr_User=(`getent passwd {1000..60000} | cut -d ":" -f 1`)   # find all normal users

    for str_User in $arr_User; do
        sudo adduser $str_User libvirt                                      # add each normal user to libvirt group
    done  
    #

    # list of input devices
    declare -a arr_InputDeviceID=`ls /dev/input/by-id`
    #

    # file changes #
    declare -a arr_file_QEMU=("
#
# NOTE: Generated by 'Auto-vfio-pci.sh'
#
user = \"$str_UID1000\"
group = \"user\"
#
hugetlbfs_mount = \"/dev/hugepages\"
#
nvram = [
   \"/usr/share/OVMF/OVMF_CODE.fd:/usr/share/OVMF/OVMF_VARS.fd\",
   \"/usr/share/OVMF/OVMF_CODE.secboot.fd:/usr/share/OVMF/OVMF_VARS.fd\",
   \"/usr/share/AAVMF/AAVMF_CODE.fd:/usr/share/AAVMF/AAVMF_VARS.fd\",
   \"/usr/share/AAVMF/AAVMF32_CODE.fd:/usr/share/AAVMF/AAVMF32_VARS.fd\"
]
#
cgroup_device_acl = [
")

    for str_InputDeviceID in $arr_InputDeviceID; do
        arr_file_QEMU+=("    \"/dev/input/by-id/$str_InputDeviceID\",")
    done

    arr_file_QEMU+=("    \"/dev/null\", \"/dev/full\", \"/dev/zero\",
    \"/dev/random\", \"/dev/urandom\",
    \"/dev/ptmx\", \"/dev/kvm\",
    \"/dev/rtc\", \"/dev/hpet\"
]
#")
    #

    # backup config file #
    if [[ -z $str_file1"_old" ]]; then
        cp $str_file1 $str_file1"_old"
    fi

    if [[ ! -z $str_file1"_old" ]]; then
        cp $str_file1"_old" $str_file1
    fi
    #

    # write to file #
    for str_line in ${arr_file_QEMU[@]}; do
        echo -e $str_line >> $str_file1
    done
    #

    # restart service #
    systemctl enable libvirtd
    systemctl restart libvirtd
    #

}
##### end Evdev #####

##### HugePages #####
function HugePages {

    # parameters #
    str_GRUB_CMDLINE_Hugepages="default_hugepagesz=1G hugepagesz=1G hugepages=0"                # default output
    int_HostMemMaxK=`cat /proc/meminfo | grep MemTotal | cut -d ":" -f 2 | cut -d "k" -f 1`     # sum of system RAM in KiB
    #

    # prompt #
    str_input1=""               # reset input
    declare -i int_count=0      # reset counter

    str_prompt="$0: HugePages is a feature which statically allocates System Memory to pagefiles.\n\tVirtual machines can use HugePages to a peformance benefit.\n\tThe greater the Hugepage size, the less fragmentation of memory, the less memory latency.\n"

    echo -e $str_prompt

    while [[ $str_input1 != "Y" && $str_input1 != "N" ]]; do

        if [[ $int_count -ge 3 ]]; then
            echo "$0: Exceeded max attempts."
            str_input1="N"                   # default selection
        else
            echo -en "$0: Setup HugePages? [Y/n]: "
            read -r str_input1
            str_input1=`echo $str_input1 | tr '[:lower:]' '[:upper:]'`
        fi

        case $str_input1 in

            "Y"|"H")
                #echo -e "$0: Continuing...\n"
                break;;

            "N")
                echo -e "$0: Skipping Hugepages...\n"
                return 0;;

            *)
                echo -e "$0: Invalid input.\n";;

        esac
        ((int_count++))     # increment counter

    done
    #

    # Hugepage size: validate input #
    str_HugePageSize=$str6
    str_HugePageSize=`echo $str_HugePageSize | tr '[:lower:]' '[:upper:]'`

    declare -i int_count=0      # reset counter

    while true; do
                 
        # attempt #
        if [[ $int_count -ge 3 ]]; then
            echo "$0: Exceeded max attempts."
            str_HugePageSize="1G"           # default selection
        else
            echo -en "$0: Enter Hugepage size and byte-size. [ 2M / 1G ]:\t"
            read -r str_HugePageSize
            str_HugePageSize=`echo $str_HugePageSize | tr '[:lower:]' '[:upper:]'`
        fi
        #

        # check input #
        case $str_HugePageSize in

            "2M")
                break;;

            "1G")
                break;;

            *)
                echo "$0: Invalid input.";;

        esac
        #

        ((int_count++))     # increment counter

    done
    #

    # Hugepage sum: validate input #
    int_HugePageNum=$str7
    declare -i int_count=0      # reset counter

    while true; do

        # attempt #
        if [[ $int_count -ge 3 ]]; then
            echo "$0: Exceeded max attempts."
            int_HugePageNum=$int_HugePageMax        # default selection
        else

            # Hugepage Size #
            if [[ $str_HugePageSize == "2M" ]]; then
                str_prefixMem="M"
                declare -i int_HugePageK=2048       # Hugepage size
                declare -i int_HugePageMin=2        # min HugePages
            fi

            if [[ $str_HugePageSize == "1G" ]]; then
                str_prefixMem="G"
                declare -i int_HugePageK=1048576    # Hugepage size
                declare -i int_HugePageMin=1        # min HugePages
            fi

            declare -i int_HostMemMinK=4194304                              # min host RAM in KiB
            declare -i int_HugePageMemMax=$int_HostMemMaxK-$int_HostMemMinK
            declare -i int_HugePageMax=$int_HugePageMemMax/$int_HugePageK   # max HugePages

            echo -en "$0: Enter number of HugePages ( num * $str_HugePageSize ). [ $int_HugePageMin to $int_HugePageMax pages ] : "
            read -r int_HugePageNum
            #

        fi
        #

        # check input #
        if [[ $int_HugePageNum -lt $int_HugePageMin || $int_HugePageNum -gt $int_HugePageMax ]]; then
            echo "$0: Invalid input."
            ((int_count++))     # increment counter
        else    
            #echo -e "$0: Continuing..."
            str_GRUB_CMDLINE_Hugepages="default_hugepagesz=$str_HugePageSize hugepagesz=$str_HugePageSize hugepages=$int_HugePageNum"
            break
        fi
        #

    done
    #

}
##### end HugePages #####

##### MultiBootSetup #####
function MultiBootSetup {

    # match existing VFIO setup install, suggest uninstall or exit #
    while [[ $bool_isVFIOsetup== false ]]; do

        ## parameters ##
        str_Distribution=`lsb_release -i`   # Linux distro name
        declare -i int_Distribution=${#str_Distribution}-16
        str_Distribution=${str_Distribution:16:int_Distribution}
        declare -a arr_rootKernel+=(`ls -1 /boot/vmli* | cut -d "z" -f 2`)                                # list of Kernels
        #

        # root Dev #
        str_rootDiskInfo=`df -hT | grep /$`
        #str_rootDev=${str_rootDiskInfo:5:4}                # example: "sda1"
        str_rootDev=${str_rootDiskInfo:0:9}                 # example: "/dev/sda1"
        str_rootUUID=`sudo lsblk -n $str_rootDev -o UUID`
        #

        # custom GRUB #
        #str_file1="/etc/grub.d/proxifiedScripts/custom"
        str_file1="/etc/grub.d/40_custom"
        echo -e "#!/bin/sh\nexec tail -n +3 \$0\n# This file provides an easy way to add custom menu entries. Simply type the\n# menu entries you want to add after this comment. Be careful not to change\n# the 'exec tail' line above." > $str_file1
        #

        # lists #
        declare -a arr_PCI_Driver_list
        declare -a arr_PCI_Driver_templist
        #

        # dependencies #
        declare -a arr_PCI_BusID
        declare -a arr_PCI_DeviceName
        declare -a arr_PCI_Driver
        declare -a arr_PCI_HW_ID
        declare -a arr_PCI_IOMMU_ID
        declare -a arr_PCI_Type
        declare -a arr_PCI_VendorName
        declare -i int_PCI_IOMMU_ID_last
        #
        ##

        # call function #
        ParsePCI $bool_isVFIOsetup $arr_PCI_BusID $arr_PCI_DeviceName $arr_PCI_Driver $arr_PCI_HW_ID $arr_PCI_IOMMU_ID $int_PCI_IOMMU_ID_last $arr_PCI_Type $arr_PCI_VendorName
        #
        
        # list IOMMU groups #
        echo -e "$0: PCI expansion slots may share 'IOMMU' groups. Therefore, PCI devices may share IOMMU groups.\n\tDevices that share IOMMU groups must be passed-through as whole or none at all.\n\tNOTE 1: Evaluate order of PCI slots to have PCI devices in individual IOMMU groups.\n\tNOTE 2: It is possible to divide IOMMU groups, but the action creates an attack vector (breaches hypervisor layer) and is not recommended (for security reasons).\n\tNOTE 3: Some onboard PCI devices may NOT share IOMMU groups. Example: a USB controller.\n$0:Review the output below before choosing which IOMMU groups (groups of PCI devices) to pass-through or not."

        # parse list of PCI devices, in order of IOMMU ID #
        for (( int_i=0; int_i<=$int_PCI_IOMMU_ID_last; int_i++ )); do

            bool_hasExternalPCI=false   # reset boolean
        
            # parse list of IOMMU IDs (in no order) #
            for (( int_j=0; int_j<${#arr_PCI_IOMMU_ID[@]}; int_j++ )); do

                str_thisPCI_Bus_ID=${arr_PCI_Bus_ID[$int_j]}
                
                # find Device Class ID, truncate first index if equal to zero (to convert to integer)
                if [[ "${str_thisPCI_Bus_ID:0:1}" == "0" ]] then              
                    declare -i int_thisPCI_DevClass_ID=${str_thisPCI_Bus_ID:1:1}
                else    
                    declare -i int_thisPCI_DevClass_ID=${str_thisPCI_Bus_ID:0:2}
                fi
                
                # is device external PCI and NOT onboard PCI #
                # match greater/equal to Device Class ID #1
                if [[ $int_thisPCI_DevClass_ID -ge 1 ]]; then
                    bool_hasExternalPCI=true            # list contains external PCI
                fi


                # match given IOMMU ID at given index
                if [[ "${arr_PCI_IOMMU_ID[$int_j]}" == "$int_i" ]]; then
                    arr_PCI_index_list+=("$int_j")      # add new index to list
                fi

            done
            #

            ## window of PCI devices in given IOMMU group ##
            echo -e "\tIOMMU ID:\t\t#$int_i"

            # parse list of PCI devices in given IOMMU group #
            for int_PCI_index in $arr_PCI_index_list; do

                # add to lists #
                arr_PCI_Driver_templist+=("${arr_PCI_Driver[$int_PCI_index]}")
                str_PCI_Driver_tempList+="${arr_PCI_Driver[$int_PCI_index]},"
                str_PCI_HW_ID_tempList+="${arr_PCI_HW_ID[$int_PCI_index]},"
                #

                # output #
                echo -e "\n\tBus ID:\t\t${arr_PCI_BusID[$int_PCI_index]}"
                echo -e "\tDeviceName:\t${arr_PCI_DeviceName[$int_PCI_index]}"
                echo -e "\tDriver:\t\t${arr_PCI_Driver[$int_PCI_index]}"
                echo -e "\tHW ID:\t\t${arr_PCI_HW_ID[$int_PCI_index]}"
                echo -e "\tType:\t\t${arr_PCI_Type[$int_PCI_index]}"
                echo -e "\tVendorName:\t${arr_PCI_VendorName[$int_PCI_index]}"
                #

            done
            ##

            if [[ $bool_hasExternalPCI == false ]] then
                echo -e "$0: No external PCI devices found in IOMMU group ID #$int_i . Skipping..."
            fi

            # prompt #
            str_input1=""               # reset input
            declare -i int_count=0      # reset counter

            while [[ $str_input1 != "Y" && $str_input1 != "N" && $bool_hasExternalPCI == true ]]; do

                if [[ $int_count -ge 3 ]]; then
                    echo "$0: Exceeded max attempts."
                    str_input2="N"                      # default selection        
                else
                    echo -en "$0: Do you wish to pass-through IOMMU group ID #$int_i ? [ Y/n ]: "
                    read -r str_input1
                    str_input1=`echo $str_input1 | tr '[:lower:]' '[:upper:]'`
                fi

                case $str_input1 in

                    "Y")
                        echo "$0: Passing-through IOMMU group ID #$int_i ..."

                        # add to lists #
                        arr_PCI_Driver_list+=($arr_PCI_Driver_templist)
                        str_PCI_Driver_list+="$str_PCI_Driver_tempList"
                        str_PCI_HW_ID_list+="$str_PCI_HW_ID_tempList"
                        #

                        break;;

                    "N")
                        echo "$0: Skipping IOMMU group ID #$int_i ..."

                        # clear variables #
                        declare -a arr_PCI_Driver_templist=""
                        str_PCI_Driver_tempList=""
                        str_PCI_HW_ID_tempList=""
                        #

                        break;;

                    *)
                        echo "$0: Invalid input.";;

                esac

                ((int_count++))     # increment counter

            done
            #   

            # remove last separator #
            if [[ ${str_PCI_Driver_list: -1} == "," ]]; then
            str_PCI_Driver_list=${str_PCI_Driver_list::-1}
            fi

            if [[ ${str_PCI_HW_ID_list: -1} == "," ]]; then
                str_PCI_HW_ID_list=${str_PCI_HW_ID_list::-1}
            fi
            #

            # GRUB command line #
            str_GRUB_CMDLINE="acpi=force apm=power_off iommu=1,pt amd_iommu=on intel_iommu=on rd.driver.pre=vfio-pci pcie_aspm=off kvm.ignore_msrs=1 $str_GRUB_CMDLINE_Hugepages modprobe.blacklist=$str_PCI_Driver_list vfio_pci.ids=$str_PCI_HW_ID_list"
            #

            ### setup Boot menu entry ###           # TODO: fix automated menu entry setup!

            # MANUAL setup Boot menu entry #        # NOTE: temporary
            echo -e "$0: Execute GRUB Customizer, Clone an existing, valid menu entry, Copy the fields 'Title' and 'Entry' below, and Paste the following output into a new menu entry, where appropriate.\n$0: DISCLAIMER: Automated GRUB menu entry feature not available yet."

            # parse Kernels #
            for str_rootKernel in ${arr_rootKernel[@]}; do

                # set Kernel #
                str_rootKernel=${str_rootKernel:1:100}          # arbitrary length
                #echo "str_rootKernel == '$str_rootKernel'"
                #

                # GRUB Menu Title #
                str_GRUBMenuTitle="$str_Distribution `uname -o`, with `uname` $str_rootKernel"
                
                if [[ ! -z $str_thisVGA_Device ]]; then
                    str_GRUBMenuTitle+=" (Xorg: $str_thisVGA_Device)'"
                fi
                #

                # MANUAL setup Boot menu entry #        # NOTE: temporary
                echo -e "\n\tTitle: '$str_GRUBMenuTitle'\n\tEntry: '$str_GRUB_CMDLINE'\n"
                #

                # GRUB custom menu #
                declare -a arr_file_customGRUB=(
"menuentry '$str_GRUBMenuTitle' {
    load_video
    insmod gzio
    if [ x\$grub_platform = xxen ]; then insmod xzio; insmod lzopio; fi
	insmod part_gpt
	insmod ext2
    set root='hd2,gpt4'
    set root='/dev/disk/by-uuid/$str_rootUUID'
    if [ x$feature_platform_search_hint = xy ]; then
	  search --no-floppy --fs-uuid --set=root --hint-bios=hd2,gpt4 --hint-efi=hd2,gpt4 --hint-baremetal=ahci2,gpt4  $str_rootUUID
	else
	  search --no-floppy --fs-uuid --set=root $str_rootUUID
	fi
    echo    'Loading Linux $str_rootKernel ...'
    linux   /boot/vmlinuz-$str_rootKernel root=UUID=$str_rootUUID $str_GRUB_CMDLINE
    echo    'Loading initial ramdisk ...'
    initrd  /boot/initrd.img-$str_rootKernel

    
"
                )

                # write to file
                #echo -e >> $str_file1    

                #for str_line in ${arr_file_customGRUB[@]}; do
                    #echo -e $str_line >> $str_file1            # TODO: fix GRUB menu entries!
                    #echo -e $str_line
                #done
                
                #echo -e >> $str_file1 
                #

            done
            #

        done
        #

    done
    #

    #sudo update-grub       # TODO: reenable when automated setup is fixed!

}
##### end MultiBootSetup #####

##### ParsePCI #####
function ParsePCI {

    # match existing VFIO setup install, suggest uninstall or exit #
    while [[ $bool_isVFIOsetup== false ]]; do
 
        ### parameters ###
        declare -i int_PCI_IOMMU_ID_last=${arr_PCI_IOMMU_ID[0]}       # greatest index of list

        ## same-size parsed lists ##                                  # NOTE: all parsed lists should be same size/length, for easy recall
        declare -a arr_PCI_BusID=(`lspci -m | cut -d '"' -f 1`)       # ex '01:00.0'
        declare -a arr_PCI_DeviceName=(`lspci -m | cut -d '"' -f 6`)  # ex 'GP104 [GeForce GTX 1070]''
        declare -a arr_PCI_HW_ID=(`lspci -n | cut -d ' ' -f 3`)       # ex '10de:1b81'
        declare -a arr_PCI_IOMMU_ID                                   # list of IOMMU IDs by order of Bus IDs
        declare -a arr_PCI_Type=(`lspci -m | cut -d '"' -f 2`)        # ex 'VGA compatible controller'
        declare -a arr_PCI_VendorName=(`lspci -m | cut -d '"' -f 4`)  # ex 'NVIDIA Corporation'

        # add empty values to pad out and make it easier for parse/recall
        declare -a arr_PCI_Driver                                     # ex 'nouveau' or 'nvidia'
        #
        ##

        # unparsed lists #
        declare -a arr_lspci_k=(`lspci -k | grep -Eiv 'DeviceName|Subsystem|modules'`)
        declare -a arr_compgen_G=(`compgen -G "/sys/kernel/iommu_groups/*/devices/*"`)
        #
        ###

        ## parse output of IOMMU IDs##
        # parse list of Bus IDs
        for (( int_i=0; int_i<${#arr_PCI_BusID[@]}; int_i++ )); do

            # reformat element
            arr_PCI_BusID[$int_i]=${arr_PCI_BusID[$int_i]::-1}

            # parse list of output (Bus IDs and IOMMU IDs) #
            for (( int_j=0; int_j<${#arr_compgen_G[@]}; int_j++ )); do

                # match output with Bus ID #
                if [[ ${arr_compgen_G[$int_j]} == *"${arr_PCI_BusID[$int_i]}"* ]]; then
                    arr_PCI_IOMMU_ID[$int_i]=`echo ${arr_compgen_G[$int_j]} | cut -d '/' -f 5`      # save IOMMU ID at given index
                    int_j=${#arr_compgen_G}                                                         # break loop
                fi
                #

            done
            #

        done
        ##

        ## parse output of drivers ##
        # parse list of output (Bus IDs and drivers)
        for (( int_i=0; int_i<${#arr_lspci_k[@]}; int_i++ )); do

            str_line1=${arr_lspci_k[$int_i]}                                    # current line
            str_PCI_BusID=`echo $str_line1 | grep -Eiv 'driver'`                # valid element
            str_PCI_Driver=`echo $str_line1 | grep 'driver' | cut -d ' ' -f 5`  # valid element

            # driver is NOT null and Bus ID is null #
            if [[ -z $str_PCI_BusID && ! -z $str_PCI_Driver && $str_PCI_Driver != 'vfio-pci' ]]; then
                arr_PCI_Driver+=("$str_PCI_Driver")                             # add to list 
            fi
            #

            # stop setup # 
            if [[ $str_PCI_Driver == 'vfio-pci' ]]; then
                #arr_PCI_Driver+=("")
                bool_VFIO_Setup=true
            fi
            #

        done
        ##

        ## save greatest index of list ##
        # parse list of IOMMU IDs #
        for (( int_i=0; int_i<${#arr_PCI_IOMMU_ID[@]}; int_i++ )); do

            # match less than current index
            if [[ $int_PCI_IOMMU_ID_last -lt ${arr_PCI_IOMMU_ID[$int_i]} ]]; then
                int_PCI_IOMMU_ID_last=${arr_PCI_IOMMU_ID[$int_i]}       # update index
            fi

        done
        ##

    done
    #

}
##### end ParsePCI #####

##### StaticSetup #####
# NOTES:
# check if MultiBootSetup ran, if true avoid list IOMMU groups with VGA devices and skip them
# if false, show all IOMMU groups
# test new setup

function StaticSetup {

    # match existing VFIO setup install, suggest uninstall or exit #
    while [[ $bool_isVFIOsetup == false ]]; do

        ## parameters ##
        declare -a arr_PCI_Driver_list
        declare -a arr_PCI_Driver_templist

        # dependencies #
        declare -a arr_PCI_BusID
        declare -a arr_PCI_DeviceName
        declare -a arr_PCI_Driver
        declare -a arr_PCI_HW_ID
        declare -a arr_PCI_IOMMU_ID
        declare -a arr_PCI_Type
        declare -a arr_PCI_VendorName
        declare -i int_PCI_IOMMU_ID_last

        ParsePCI $bool_isVFIOsetup $arr_PCI_BusID $arr_PCI_DeviceName $arr_PCI_Driver $arr_PCI_HW_ID $arr_PCI_IOMMU_ID $int_PCI_IOMMU_ID_last $arr_PCI_Type $arr_PCI_VendorName
        #

        # files #
        str_file1="/etc/default/grub"
        str_file2="/etc/initramfs-tools/modules"
        str_file3="/etc/modules"
        str_file4="/etc/modprobe.d/pci-blacklists.conf"
        str_file5="/etc/modprobe.d/vfio.conf"
        #
        ##
    
        # list IOMMU groups #
        echo -e "$0: PCI expansion slots may share 'IOMMU' groups. Therefore, PCI devices may share IOMMU groups.\n\tDevices that share IOMMU groups must be passed-through as whole or none at all.\n\tNOTE 1: Evaluate order of PCI slots to have PCI devices in individual IOMMU groups.\n\tNOTE 2: It is possible to divide IOMMU groups, but the action creates an attack vector (breaches hypervisor layer) and is not recommended (for security reasons).\n\tNOTE 3: Some onboard PCI devices may NOT share IOMMU groups. Example: a USB controller.\n$0:Review the output below before choosing which IOMMU groups (groups of PCI devices) to pass-through or not."

        # parse list of PCI devices, in order of IOMMU ID #
        for (( int_i=0; int_i<=$int_PCI_IOMMU_ID_last; int_i++ )); do

            bool_hasExternalPCI=false   # reset boolean
        
            # parse list of IOMMU IDs (in no order) #
            for (( int_j=0; int_j<${#arr_PCI_IOMMU_ID[@]}; int_j++ )); do

                str_thisPCI_Bus_ID=${arr_PCI_Bus_ID[$int_j]}
                
                # find Device Class ID, truncate first index if equal to zero (to convert to integer)
                if [[ "${str_thisPCI_Bus_ID:0:1}" == "0" ]] then              
                    declare -i int_thisPCI_DevClass_ID=${str_thisPCI_Bus_ID:1:1}
                else    
                    declare -i int_thisPCI_DevClass_ID=${str_thisPCI_Bus_ID:0:2}
                fi
                
                # is device external PCI and NOT onboard PCI #
                # match greater/equal to Device Class ID #1
                if [[ $int_thisPCI_DevClass_ID -ge 1 ]]; then
                    bool_hasExternalPCI=true            # list contains external PCI
                fi


                # match given IOMMU ID at given index
                if [[ "${arr_PCI_IOMMU_ID[$int_j]}" == "$int_i" ]]; then
                    arr_PCI_index_list+=("$int_j")      # add new index to list
                fi

            done
            #

            ## window of PCI devices in given IOMMU group ##
            echo -e "\tIOMMU ID:\t\t#$int_i"

            # parse list of PCI devices in given IOMMU group #
            for int_PCI_index in $arr_PCI_index_list; do

                # add to lists #
                arr_PCI_Driver_templist+=("${arr_PCI_Driver[$int_PCI_index]}")
                str_PCI_Driver_tempList+="${arr_PCI_Driver[$int_PCI_index]},"
                str_PCI_HW_ID_tempList+="${arr_PCI_HW_ID[$int_PCI_index]},"
                #

                # output #
                echo -e "\n\tBus ID:\t\t${arr_PCI_BusID[$int_PCI_index]}"
                echo -e "\tDeviceName:\t${arr_PCI_DeviceName[$int_PCI_index]}"
                echo -e "\tDriver:\t\t${arr_PCI_Driver[$int_PCI_index]}"
                echo -e "\tHW ID:\t\t${arr_PCI_HW_ID[$int_PCI_index]}"
                echo -e "\tType:\t\t${arr_PCI_Type[$int_PCI_index]}"
                echo -e "\tVendorName:\t${arr_PCI_VendorName[$int_PCI_index]}"
                #

            done
            ##

            if [[ $bool_hasExternalPCI == false ]] then
                echo -e "$0: No external PCI devices found in IOMMU group ID #$int_i . Skipping..."
            fi

            # prompt #
            str_input1=""               # reset input
            declare -i int_count=0      # reset counter

            while [[ $str_input1 != "Y" && $str_input1 != "N" && $bool_hasExternalPCI == true ]]; do

                if [[ $int_count -ge 3 ]]; then
                    echo "$0: Exceeded max attempts."
                    str_input2="N"                      # default selection        
                else
                    echo -en "$0: Do you wish to pass-through IOMMU group ID #$int_i ? [ Y/n ]: "
                    read -r str_input1
                    str_input1=`echo $str_input1 | tr '[:lower:]' '[:upper:]'`
                fi

                case $str_input1 in

                    "Y")
                        echo "$0: Passing-through IOMMU group ID #$int_i ..."

                        # add to lists #
                        arr_PCI_Driver_list+=($arr_PCI_Driver_templist)
                        str_PCI_Driver_list+="$str_PCI_Driver_tempList"
                        str_PCI_HW_ID_list+="$str_PCI_HW_ID_tempList"
                        #

                        break;;

                    "N")
                        echo "$0: Skipping IOMMU group ID #$int_i ..."

                        # clear variables #
                        declare -a arr_PCI_Driver_templist=""
                        str_PCI_Driver_tempList=""
                        str_PCI_HW_ID_tempList=""
                        #

                        break;;

                    *)
                        echo "$0: Invalid input.";;

                esac

                ((int_count++))     # increment counter

            done
            #   

        done
        #

        # remove last separator #
        if [[ ${str_PCI_Driver_list: -1} == "," ]]; then
            str_PCI_Driver_list=${str_PCI_Driver_list::-1}
        fi

        if [[ ${str_PCI_HW_ID_list: -1} == "," ]]; then
            str_PCI_HW_ID_list=${str_PCI_HW_ID_list::-1}
        fi
        #

        # VFIO soft dependencies #
        for str_thisPCI_Driver in $arr_PCI_Driver_list; do
            str_PCI_Driver_list_softdep="softdep $str_thisPCI_Driver pre: vfio-pci\n$str_thisPCI_Driver"
        done
        #

        ## GRUB ##
        bool_str_file1=false
        str_GRUB="GRUB_CMDLINE_DEFAULT=\"acpi=force apm=power_off iommu=1,pt amd_iommu=on intel_iommu=on rd.driver.pre=vfio-pci pcie_aspm=off kvm.ignore_msrs=1 $str_GRUB_CMDLINE_Hugepages modprobe.blacklist=$str_PCI_Driver_list vfio_pci.ids=$str_PCI_HW_ID_list\""

        # backup file
        if [[ -z $str_file1"_old" ]]; then
            cp $str_file1 $str_file1"_old"
        fi
        #

        # find GRUB line and comment out #
        while read str_line_1; do

            # match line #
            if [[ $str_line_1 != *"GRUB_CMDLINE_DEFAULT"* && $str_line_1 != *"#GRUB_CMDLINE_DEFAULT"* ]]; then
                bool_str_file1=true
                str_line1=$str_GRUB                         # update line
            fi

            echo -e $str_line_1  >> $str_file1"_new"        # append to new file

        done < $str_file_1
        #

        # no GRUB line found, append at end #
        if [[ $bool_str_file1 == false ]]; then
            echo -e "\n$str_GRUB"  >> $str_file1"_new"
        fi
        #

        mv $str_file1"_new" $str_file1  # overwrite current file with new file
        ##

        ## initramfs-tools ##
        declare -a arr_file2=(
"# List of modules that you want to include in your initramfs.
# They will be loaded at boot time in the order below.
#
# Syntax:  module_name [args ...]
#
# You must run update-initramfs(8) to effect this change.
#
# Examples:
#
# raid1
# sd_mod
#
# NOTE: GRUB command line is an easier and cleaner method if vfio-pci grabs all hardware.
# Example: Reboot hypervisor (Linux) to swap host graphics (Intel, AMD, NVIDIA) by use-case (AMD for Win XP, NVIDIA for Win 10).
# NOTE: If you change this file, run 'update-initramfs -u -k all' afterwards to update.

# Soft dependencies and PCI kernel drivers:
$str_PCI_Driver_list_softdep

vfio
vfio_iommu_type1
vfio_virqfd

# GRUB command line and PCI hardware IDs:
options vfio_pci ids=$str_PCI_HW_ID_list
vfio_pci ids=$str_PCI_HW_ID_list
vfio_pci"
)
        echo ${arr_file2[@]} > $str_file2
        ##

        ## /etc/modules ##
        declare -a arr_file3=(
"# /etc/modules: kernel modules to load at boot time.
#
# This file contains the names of kernel modules that should be loaded
# at boot time, one per line. Lines beginning with \"#\" are ignored.
#
# NOTE: GRUB command line is an easier and cleaner method if vfio-pci grabs all hardware.
# Example: Reboot hypervisor (Linux) to swap host graphics (Intel, AMD, NVIDIA) by use-case (AMD for Win XP, NVIDIA for Win 10).
# NOTE: If you change this file, run 'update-initramfs -u -k all' afterwards to update.
#
vfio
vfio_iommu_type1
vfio_pci
vfio_virqfd
kvm
kvm_intel
apm power_off=1

# In terminal, execute \"lspci -nnk\".

# GRUB kernel parameters:
vfio_pci ids=$str_PCI_HW_ID_list"
)
        echo ${arr_file3[@]} > $str_file3
        ##

        ## /etc/modprobe.d/pci-blacklist.conf ##
        for str_thisPCI_Driver in $arr_PCI_Driver_list[@]; do
            echo "blacklist $str_thisPCI_Driver" >> $str_file4
        done
        ##

        ## /etc/modprobe.d/vfio.conf ##
        declare -a arr_file5=(
"# NOTE: If you change this file, run 'update-initramfs -u -k all' afterwards to update.
# Soft dependencies:
$str_PCI_Driver_list_softdep

# PCI hardware IDs:
options vfio_pci ids=$str_PCI_HW_ID_list")
        echo ${arr_file5[@]} > $str_file5
        ##

    done
    #

}
##### end StaticSetup #####

##### UninstallMultiBootSetup #####
function UninstallMultiBootSetup {



}
##### end UninstallMultiBootSetup #####

##### UninstallStaticSetup #####
function UninstallStaticSetup {

    ## parameters ##  
    str_file1="/etc/default/grub"                           # no backup, then warn user to uncomment changes                         
    str_file2="/etc/initramfs-tools/modules"                # no backup, then restore from script
    str_file3="/etc/modules"                                # no backup, then restore from script
    str_file4="/etc/modprobe.d/pci-blacklists.conf"         # example:  "blacklist nvidia\nblacklist radeon"
    str_file5="/etc/modprobe.d/vfio-pci.conf"               # remove

    declare -a arr_file2=(
"# List of modules that you want to include in your initramfs.
# They will be loaded at boot time in the order below.
#
# Syntax:  module_name [args ...]
#
# You must run update-initramfs(8) to effect this change.
#
# Examples:
#
# raid1
# sd_mod
#
# NOTE: GRUB command line is an easier and cleaner method if vfio-pci grabs all hardware.
# Example: Reboot hypervisor (Linux) to swap host graphics (Intel, AMD, NVIDIA) by use-case (AMD for Win XP, NVIDIA for Win 10).
# NOTE: If you change this file, run 'update-initramfs -u -k all' afterwards to update.

# Soft dependencies and PCI kernel drivers:
# Example:
#   softdep PCI_DRIVER pre: vfio-pci PCI_DRIVER
#   PCI_DRIVER

#vfio
#vfio_iommu_type1
#vfio_virqfd

# GRUB command line and PCI hardware IDs:
#options vfio_pci ids=
#vfio_pci ids=
#vfio_pci"

    declare -a arr_file3=(
"# /etc/modules: kernel modules to load at boot time.
#
# This file contains the names of kernel modules that should be loaded
# at boot time, one per line. Lines beginning with \"#\" are ignored.
#
# NOTE: GRUB command line is an easier and cleaner method if vfio-pci grabs all hardware.
# Example: Reboot hypervisor (Linux) to swap host graphics (Intel, AMD, NVIDIA) by use-case (AMD for Win XP, NVIDIA for Win 10).
# NOTE: If you change this file, run 'update-initramfs -u -k all' afterwards to update.
#
#vfio
#vfio_iommu_type1
#vfio_pci
#vfio_virqfd
kvm
#kvm_intel
#apm power_off=1

# In terminal, execute \"lspci -nnk\".

# GRUB kernel parameters:
#vfio_pci ids="
)

    declare -a arr_file5=(
"# NOTE: If you change this file, run 'update-initramfs -u -k all' afterwards to update.
# Soft dependencies:
# Example
#softdep PCI_DRIVER pre: vfio-pci PCI_DRIVER

# PCI hardware IDs:
#options vfio_pci ids="
)
    ##


    ## restore backups of files ##
    if [[ ! -z $str_file1"_old" ]]
        then cp $str_file1"_old" $str_file1
    else echo -e "$0: WARNING: No backup found for '$str_file1'. Undo changes manually for file."; fi

    if [[ ! -z $str_file2"_old" ]]
        then cp $str_file2"_old" $str_file2
    else echo ${arr_file2[@]} > $str_file2; fi

    if [[ ! -z $str_file3"_old" ]]
        then cp $str_file3"_old" $str_file3
    else echo ${arr_file3[@]} > $str_file3; fi

    if [[ ! -z $str_file4 ]]
        then rm $str_file4; fi
    
    if [[ ! -z $str_file5 ]]
        then echo ${arr_file5[@]} > $str_file5; fi
    ##

    sudo update-grub                    # update GRUB
    sudo update-initramfs -u -k all     # update INITRAMFS

}
##### end UninstallStaticSetup #####


##### ZRAM #####
function ZRAM {

    # parameters #
    str_file1="/etc/default/zramswap"
    str_file2="/etc/default/zram-swap"
    #

    # prompt #
    str_input1=""               # reset input
    declare -i int_count=0      # reset counter

    str_prompt="$0: ZRAM allocates RAM as a compressed swapfile.\n\tThe default compression method \"lz4\", at a ratio of 2:1 to 5:2, offers the greatest performance."

    echo -e $str_prompt
    str_input1=""

    while [[ $str_input1 != "Y" && $str_input1 != "Z" && $str_input1 != "N" ]]; do

        if [[ $int_count -ge 3 ]]; then
            echo "$0: Exceeded max attempts."
            str_input1="N"                   # default selection       
        else
            echo -en "$0: Setup ZRAM? [ Y/n ]: "
            read -r str_input1
            str_input1=`echo $str_input1 | tr '[:lower:]' '[:upper:]'`
        fi

        case $str_input1 in

            "Y"|"Z")
                #echo -e "$0: Continuing...\n"
                break;;

            "N")
                echo -e "$0: Skipping...\n"
                return 0;;

            *)
                echo "$0: Invalid input.";;

        esac
        ((int_count++))     # increment counter

    done
    #

    # parameters #
    int_HostMemMaxK=`cat /proc/meminfo | grep MemTotal | cut -d ":" -f 2 | cut -d "k" -f 1`     # sum of system RAM in KiB
    str_GitHub_Repo="FoundObjects/zram-swap"
    #

    # check for zram-utils #
    if [[ ! -z $str_file1 ]]; then
        apt install -y git zram-tools
        systemctl stop zramswap
        systemctl disable zramswap
    fi
    #

    # check for local repo #
    #if [[ ! -z "/root/git/$str_GitHub_Repo" ]]; then

        #cd /root/git/`echo $str_GitHub_Repo | cut -d '/' -f 1`    
        #git pull https://www.github.com/$str_GitHub_Repo
    
    #fi

    if [[ -z "/root/git/$str_GitHub_Repo" ]]; then
        mkdir /root/git
        mkdir /root/git/`echo $str_GitHub_Repo | cut -d '/' -f 1`
        cd /root/git/`echo $str_GitHub_Repo | cut -d '/' -f 1`
        git clone https://www.github.com/$str_GitHub_Repo
    fi
    #

    # check for zram-swap #
    if [[ -z $str_file2 ]]; then
        cd /root/git/$str_GitHub_Repo
        sh ./install.sh
    fi
    #

    # disable ZRAM swap #
    if [[ `sudo swapon -v | grep /dev/zram*` == "/dev/zram"* ]]; then
        sudo swapoff /dev/zram*
    fi
    #
    
    # backup config file #
    if [[ -z $str_file2"_old" ]]; then
        cp $str_file2 $str_file2"_old"
    fi
    #

    # find HugePage size #
    str_HugePageSize="1G"

    if [[ $str_HugePageSize == "2M" ]]; then
        declare -i int_HugePageSizeK=2048
    fi

    if [[ $str_HugePageSize == "1G" ]]; then
        declare -i int_HugePageSizeK=1048576
    fi
    #

    ## find free memory ##
    declare -i int_HostMemMaxG=$((int_HostMemMaxK/1048576))
    declare -i int_SysMemMaxG=$((int_HostMemMaxG+1))                    # use modulus?

    # free memory # 
    if [[ ! -z $int_HugePageNum || ! -z $int_HugePageSizeK ]]; then
        declare -i int_HostMemFreeG=$((int_HugePageNum*int_HugePageSizeK/1048576))
    else
        declare -i int_HostMemFreeG=4
    fi
    int_HostMemFreeG=$((int_SysMemMaxG-int_HostMemFreeG))
    #
    ##

    # setup ZRAM #
    if [[ $int_HostMemFreeG -le 8 ]]; then
        declare -i int_ZRAM_SizeG=4
    else
        declare -i int_ZRAM_SizeG=$int_SysMemMaxG/2
    fi

    declare -i int_denominator=$int_SysMemMaxG/$int_ZRAM_SizeG
    #str_input_ZRAM="_zram_fixedsize=\"${int_ZRAM_SizeG}G\""
    #

    # file 3
    declare -a arr_file_ZRAM=(
"# compression algorithm to employ (lzo, lz4, zstd, lzo-rle)
# default: lz4
_zram_algorithm=\"lz4\"

# portion of system ram to use as zram swap (expression: \"1/2\", \"2/3\", \"0.5\", etc)
# default: \"1/2\"
_zram_fraction=\"1/$int_denominator\"

# setting _zram_swap_debugging to any non-zero value enables debugging
# default: undefined
#_zram_swap_debugging=\"beep boop\"

# expected compression factor; set this by hand if your compression results are
# drastically different from the estimates below
#
# Note: These are the defaults coded into /usr/local/sbin/zram-swap.sh; don't alter
#       these values, use the override variable '_comp_factor' below.
#
# defaults if otherwise unset:
#       lzo*|zstd)  _comp_factor=\"3\"   ;; # expect 3:1 compression from lzo*, zstd
#       lz4)        _comp_factor=\"2.5\" ;; # expect 2.5:1 compression from lz4
#       *)          _comp_factor=\"2\"   ;; # default to 2:1 for everything else
#
#_comp_factor=\"2.5\"

# if set skip device size calculation and create a fixed-size swap device
# (size, in MiB/GiB, eg: \"250M\" \"500M\" \"1.5G\" \"2G\" \"6G\" etc.)
#
# Note: this is the swap device size before compression, real memory use will
#       depend on compression results, a 2-3x reduction is typical
#
#_zram_fixedsize=\"4G\"

# vim:ft=sh:ts=2:sts=2:sw=2:et:"
)
    #

    # write to file #
    rm $str_file2

    for str_line in ${arr_file_ZRAM[@]}; do
        echo -e $str_line >> $str_file2
    done
    #
    
    systemctl restart zram-swap     # restart service

}
##### end ZRAM #####

########## end functions ##########

########## main ##########

# check if sudo #
if [[ `whoami` != "root" ]]; then
    echo "$0: Script must be run as Sudo or Root!"; exit 0
fi
#

# a canary to check for previous VFIO setup installation #
bool_VFIO_Setup=false
#

# check if system supports IOMMU #
if ! compgen -G "/sys/kernel/iommu_groups/*/devices/*" > /dev/null; then
    echo "$0: AMD IOMMU/Intel VT-D is NOT enabled in the BIOS/UEFI."
fi
#

# set IFS #
SAVEIFS=$IFS   # Save current IFS (Internal Field Separator)
IFS=$'\n'      # Change IFS to newline char
#

# call functions #
while [[ $bool_isVFIOsetup == false ]]; do

    Prompts $bool_VFIO_Setup
    echo -e "$0: DISCLAIMER: Please review changes made.\n\tIf a given network (Ethernet, WLAN) or storage controller (NVME, SATA) is necessary for the Host machine, and the given device is passed-through, the Host machine will lose access to it."

done
#

# prompt uninstall setup or exit #
if [[ $bool_isVFIOsetup == true ]]; then

    echo -e "$0: WARNING: System is already setup with VFIO Passthrough.\n$0: To continue with a new VFIO setup:\n\tExecute the 'Uninstall VFIO setup,'\n\tReboot the system,\n\tExecute '$0'."

    while [[ $bool_isVFIOsetup== true ]]; do
    
        if [[ $int_count -ge 3 ]]; then
            echo "$0: Exceeded max attempts."
            str_input1="N"      # default selection
        else
            echo -en "$0: Uninstall VFIO setup on this system? [ Y/n ]: "
            read -r str_input1
            str_input1=`echo $str_input1 | tr '[:lower:]' '[:upper:]'`
        fi

        case $str_input1 in

            "Y")
                echo -e "$0: Uninstalling VFIO setup...\n"
                UninstallMultiBootSetup
                UninstallStaticSetup
                break;;

            "N")
                echo -e "$0: Skipping...\n"
                exit 0

            *)
                echo "$0: Invalid input.";;

        esac

        ((int_count++))     # increment counter

        done
        #

    done

fi
#

# reset IFS #
IFS=$SAVEIFS   # Restore original IFS
#

exit 0

########## end main ##########
