#!/bin/bash sh

# check if sudo/root #
if [[ `whoami` != "root" ]]; then
    echo -e "$0: WARNING: Script must be run as Sudo or Root! Exiting."
    exit 0
fi
#

# input variables #
bool_isVFIOsetup=$2
str_GRUB_CMDLINE_Hugepages=""

str_file0=`ls $(pwd) | grep -i 'hugepages' | grep -i '.log'ls $(pwd) | grep -i 'hugepages' | grep -i '.log'`
if [[ -z $str_file0 ]]; then
    echo "$0: Hugepages logfile does not exist. Should you wish to enable Hugepages, execute both '"`ls $(pwd) | grep -i 'hugepages' | grep -i '.bash'`"' and '$0'."
else
    while read str_line1; do
        if [[ $str_line1 == *"hugepagesz="* ]]; then str_GRUB_CMDLINE_Hugepages+="default_$str_line1 $str_line1"; fi    # parse hugepage size
        if [[ $str_line1 == *"hugepages="* ]]; then str_GRUB_CMDLINE_Hugepages+=" $str_line1"; fi                       # parse hugepage num
    done < $str_file0
fi
#

## user input ##
str_input1=""

# precede with echo prompt for input #
# ask user for input then validate #
function ReadInput {
    if [[ -z $str_input1 ]]; then read str_input1; fi

    str_input1=$(echo $str_input1 | tr '[:lower:]' '[:upper:]')
    str_input1=${str_input1:0:1}
    ValidInput $str_input1
}

# validate input, ask again, default answer NO #
function ValidInput {
    declare -i int_count=0    # reset counter
    echo $str_input1
    while true; do
        # passthru input variable if it is valid #
        if [[ $1 == "Y"* || $1 == "y"* ]]; then
            str_input1=$1     # input variable
            break
        fi
        #

        # manual prompt #
        if [[ $int_count -ge 3 ]]; then       # auto answer
            echo -e "$0: Exceeded max attempts."
            str_input1="N"                    # default input     # NOTE: change here
        else                                        # manual prompt
            echo -en "$0: [Y/n]: "
            read str_input1
            # string to upper
            str_input1=$(echo $str_input1 | tr '[:lower:]' '[:upper:]')
            str_input1=${str_input1:0:1}
            #
        fi
        #

        case $str_input1 in
            "Y"|"N")
                break
            ;;
            *)
                echo -e "$0: Invalid input."
            ;;
        esac  
        ((int_count++))   # counter
    done  
}
##

## ParsePCI ##
function ParsePCI {
 
    # parameters #
    # same-size parsed lists #                                    # NOTE: all parsed lists should be same size/length, for easy recall
    declare -a arr_PCI_BusID=(`lspci -m | cut -d '"' -f 1`)       # ex '01:00.0'
    declare -a arr_PCI_DeviceName=(`lspci -m | cut -d '"' -f 6`)  # ex 'GP104 [GeForce GTX 1070]''
    declare -a arr_PCI_HW_ID=(`lspci -n | cut -d ' ' -f 3`)       # ex '10de:1b81'
    declare -a arr_PCI_IOMMU_ID                                   # list of IOMMU IDs by order of Bus IDs
    declare -a arr_PCI_Type=(`lspci -m | cut -d '"' -f 2`)        # ex 'VGA compatible controller'
    declare -a arr_PCI_VendorName=(`lspci -m | cut -d '"' -f 4`)  # ex 'NVIDIA Corporation'

    # add empty values to pad out and make it easier for parse/recall #
    declare -a arr_PCI_Driver                                     # ex 'nouveau' or 'nvidia'
    ##

    # unparsed lists #
    declare -a arr_lspci_k=(`lspci -k | grep -Eiv 'DeviceName|Subsystem|modules'`)      # PCI device list with Bus ID, name, and (likely) kernel driver
    declare -a arr_compgen_G=(`compgen -G "/sys/kernel/iommu_groups/*/devices/*"`)      # IOMMU group IDs in no order
    #

    declare -i int_PCI_IOMMU_ID_last=0       # greatest value index of list
    #

    # reformat input #
    # parse list of Bus IDs
    for (( int_i=0; int_i<${#arr_PCI_BusID[@]}; int_i++ )); do 
        arr_PCI_BusID[$int_i]=${arr_PCI_BusID[$int_i]::-1}          # reformat element
    done
    #

    # parse output of IOMMU IDs # 
    # parse list of Bus IDs
    for (( int_i=0; int_i<${#arr_PCI_BusID[@]}; int_i++ )); do

        # parse list of output (Bus IDs and IOMMU IDs) #
        for (( int_j=0; int_j<${#arr_compgen_G[@]}; int_j++ )); do

            # match output with Bus ID #
            if [[ ${arr_compgen_G[$int_j]} == *"${arr_PCI_BusID[$int_i]}"* ]]; then
                arr_PCI_IOMMU_ID[$int_i]=`echo ${arr_compgen_G[$int_j]} | cut -d '/' -f 5`      # save IOMMU ID at given index
                int_j=${#arr_compgen_G[@]}                                                      # break loop
            fi
        done
        #
    done
    #

    # parse output of drivers #
    # parse list of output (Bus IDs and drivers)
    for (( int_i=0; int_i<${#arr_lspci_k[@]}; int_i++ )); do

        str_line1=${arr_lspci_k[$int_i]}                                    # current line
        str_PCI_BusID=`echo $str_line1 | grep -Eiv 'driver'`                # valid element
        str_PCI_Driver=`echo $str_line1 | grep 'driver' | cut -d ' ' -f 5`  # valid element

        # driver is NOT null and Bus ID is null #
        if [[ -z $str_PCI_BusID && ! -z $str_PCI_Driver && $str_PCI_Driver != 'vfio-pci' ]]; then arr_PCI_Driver+=("$str_PCI_Driver"); fi   # add to list

        # stop setup # 
        if [[ $str_PCI_Driver == 'vfio-pci' ]]; then
            #arr_PCI_Driver+=("")
            bool_isVFIOsetup=true
        fi
    done
    #

    # save greatest index of list #
    # parse list of IOMMU IDs #
    for (( int_i=0; int_i<${#arr_PCI_IOMMU_ID[@]}; int_i++ )); do

        # match less than current index #
        if [[ $int_PCI_IOMMU_ID_last -lt ${arr_PCI_IOMMU_ID[$int_i]} ]]; then int_PCI_IOMMU_ID_last=${arr_PCI_IOMMU_ID[$int_i]}; fi       # update index
    done
    #
}
## end ParsePCI ##

# useful write to file, change to read file for vfio setup (hugepages cmd line)

#str_GRUB_CMDLINE_Hugepages="default_hugepagesz=$str_HugePageSize hugepagesz=$str_HugePageSize hugepages=$int_HugePageNum"   # shared variable with other function
#echo -e "$0: Writing logfile. Contents: partial text for GRUB menu entry."
        
#str_file1='~/'$(pwd)$0'.log'
#echo $str_GRUB_CMDLINE_Hugepages >> $str_file1



##### StaticSetup_new #####
function StaticSetup_new {

    ## NOTE:
    ##  i want to make the function parse all devices, and a given IOMMU group.
    ##  ask user to either passthrough (add to list) or not (subtract from list/create a given boot menu entry)
    ## OR
    ## auto parse IOMMU groups, add each groups drivers and HW IDs into separate 
    ## and move y/n question to StaticSetup

    ## if MultiBootSetup ran, save each index of IOMMU group to not passthrough and avoid.

    # match existing VFIO setup install, suggest uninstall or exit #

        ## parameters ##
        # files #
        #str_file1="/etc/default/grub"
        #str_file2="/etc/initramfs-tools/modules"
        #str_file3="/etc/modules"
        #str_file4="/etc/modprobe.d/pci-blacklists.conf"
        #str_file5="/etc/modprobe.d/vfio.conf"
        # logfiles #    # NOTE: keep?
        str_file1=$(pwd)"grub.log"
        str_file2=$(pwd)"initramfs-modules.log"
        str_file3=$(pwd)"modules.log"
        str_file4=$(pwd)"pci-blacklists.conf.log"
        str_file5=$(pwd)"vfio.conf.log"
        #

        # lists #
        declare -a arr_PCI_Driver_list
        str_PCI_Driver_list=""
        str_PCI_HW_ID_list=""
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
        ##

        # call function #
        ParsePCI $bool_isVFIOsetup $arr_PCI_BusID $arr_PCI_DeviceName $arr_PCI_Driver $arr_PCI_HW_ID $arr_PCI_IOMMU_ID $int_PCI_IOMMU_ID_last $arr_PCI_Type $arr_PCI_VendorName
        #
        
        # list IOMMU groups #
        echo -e "$0: PCI expansion slots may share 'IOMMU' groups. Therefore, PCI devices may share IOMMU groups.\n\tDevices that share IOMMU groups must be passed-through as whole or none at all.\n\tNOTE 1: Evaluate order of PCI slots to have PCI devices in individual IOMMU groups.\n\tNOTE 2: It is possible to divide IOMMU groups, but the action creates an attack vector (breaches hypervisor layer) and is not recommended (for security reasons).\n\tNOTE 3: Some onboard PCI devices may NOT share IOMMU groups. Example: a USB controller.\n$0:Review the output below before choosing which IOMMU groups (groups of PCI devices) to pass-through or not."

        # parse list of PCI devices, in order of IOMMU ID #
        for (( int_i=0; int_i<=$int_PCI_IOMMU_ID_last; int_i++ )); do

            bool_hasExternalPCI=false   # reset boolean
            bool_hasExternalVGA=false   # reset boolean
        
            # parse list of IOMMU IDs (in no order) #
            for (( int_j=0; int_j<${#arr_PCI_IOMMU_ID[@]}; int_j++ )); do

                # match given IOMMU ID at given index #
                if [[ "${arr_PCI_IOMMU_ID[$int_j]}" == "$int_i" ]]; then
                    arr_PCI_index_list+=("$int_j")      # add new index to list
                fi
                #

            done
            #

            ## window of PCI devices in given IOMMU group ##
            echo -e "\tIOMMU ID:\t\t#$int_i"

            bool_VGA_IOMMU_{$int_i}=false

            # parse list of PCI devices in given IOMMU group #
            for int_PCI_index in $arr_PCI_index_list; do

                str_thisPCI_BusID=${arr_PCI_BusID[$int_j]}
                
                # find Device Class ID, truncate first index if equal to zero (to convert to integer)
                if [[ "${str_thisPCI_BusID:0:1}" == "0" ]]; then              
                    str_thisPCI_BusID=${str_thisPCI_BusID:1:1}
                else    
                    str_thisPCI_BusID=${str_thisPCI_BusID:0:2}
                fi
                #
                
                # match greater/equal to Device Class ID #1
                if [[ $str_thisPCI_BusID -ge 1 ]]; then
                
                    # add IOMMU group information to lists #
                    str_PCI_IOMMU_Driver_list_{$int_i}+="${arr_PCI_Driver[$int_PCI_index]},"
                    str_PCI_IOMMU_HW_ID_list_{$int_i}+="${arr_PCI_HW_ID[$int_PCI_index]},"
                    #

                    bool_hasExternalPCI=true               # list contains external PCI
                fi
                #

                # is device external and is VGA #
                if [[ $str_thisPCI_BusID -ge 1 && ${arr_PCI_Type[$int_PCI_index]} == *"VGA"* ]]; then   
                    str_VGA_IOMMU_DeviceName_{$int_i}=${arr_PCI_DeviceName[$int_PCI_index]}
                    bool_hasExternalVGA=true               # list contains external VGA
                fi
                #

                # output #
                echo -e "\n\tBus ID:\t\t${arr_PCI_BusID[$int_PCI_index]}"
                echo -e "\tDeviceName:\t${arr_PCI_DeviceName[$int_PCI_index]}"
                echo -e "\tType:\t\t${arr_PCI_Type[$int_PCI_index]}"
                #

            done
            ##

            ## prompt ##
            declare -i int_count=0      # reset counter

            # match if list does not contain VGA #
            # do passthrough all devices #
            if [[ $bool_hasExternalVGA == false ]]; then
                echo -e "$0: No external VGA device(s) found in IOMMU group ID #$int_i ."
                str_input1="Y"
            fi
            #

            # match if list does NOT contain external PCI #
            # do NOT passthrough all devices #
            if [[ $bool_hasExternalPCI == false ]]; then
                echo -e "$0: No external PCI device(s) found in IOMMU group ID #$int_i ."
                str_input1="N"
            fi
            #

            # match if list does NOT contain external PCI #
            # do NOT passthrough all devices #
            if [[ $bool_hasExternalVGA == true ]]; then
                echo -e "$0: External VGA device(s) found in IOMMU group ID #$int_i ."
                str_input1="N"
            fi
            # 

            while true; do

                if [[ $int_count -ge 3 ]]; then
                    echo "$0: Exceeded max attempts."
                    str_input1="N"                      # default selection        
                else
                    echo -en "$0: Do you wish to pass-through IOMMU group ID #$int_i ? [ Y/n ]: "
                    read -r str_input1
                    str_input1=`echo $str_input1 | tr '[:lower:]' '[:upper:]'`
                fi

                case $str_input1 in
                    "Y")
                        echo "$0: Passing-through IOMMU group ID #$int_i ..."

                        # add IOMMU group to VFIO pass-through lists #
                        arr_PCI_Driver_list+=($arr_PCI_IOMMU_{$int_i}_Driver_list)
                        str_PCI_Driver_list+=$str_PCI_IOMMU_{$int_i}_Driver_list
                        str_PCI_HW_ID_list+=$str_PCI_IOMMU_{$int_i}_HW_ID_list
                        #

                        break;;
                    "N")
                        echo "$0: Skipping IOMMU group ID #$int_i ..."
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
"# NOTE: Generated by 'portellam/VFIO-setup'  # START #
# List of modules that you want to include in your initramfs.
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
vfio_pci
# END #"
)
        #echo ${arr_file2[@]} > $str_file2
        echo ${arr_file2[@]}
        ##

        ## /etc/modules ##
        declare -a arr_file3=(
"# NOTE: Generated by 'portellam/VFIO-setup'  # START #
# /etc/modules: kernel modules to load at boot time.
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
vfio_pci ids=$str_PCI_HW_ID_list
# END #"
)
        #echo ${arr_file3[@]} > $str_file3
        echo ${arr_file3[@]}
        ##

        ## /etc/modprobe.d/pci-blacklist.conf ##
        echo "# NOTE: Generated by 'portellam/VFIO-setup'  # START #" >> $str_file4
        #for str_thisPCI_Driver in $arr_PCI_Driver_list[@]; do
            #echo "blacklist $str_thisPCI_Driver" >> $str_file4
        #done
        echo "# END #" >> $str_file4
        ##

        ## /etc/modprobe.d/vfio.conf ##
        declare -a arr_file5=(
"# NOTE: Generated by 'portellam/VFIO-setup'  # START #
# NOTE: If you change this file, run 'update-initramfs -u -k all' afterwards to update.
# Soft dependencies:
$str_PCI_Driver_list_softdep

# PCI hardware IDs:
options vfio_pci ids=$str_PCI_HW_ID_list
# END #")
        #echo ${arr_file5[@]} > $str_file5
        echo ${arr_file5[@]}
        ##

    done
    #

}
## end StaticSetup_new ##

#
while [[ $bool_isVFIOsetup == false ]]; do

    ParsePCI $bool_isVFIOsetup

    # prompt #
    declare -i int_count=0      # reset counter

    str_prompt="$0: Setup VFIO by 'Multi-Boot' or Statically?\n\tMulti-Boot Setup includes adding GRUB boot options, each with one specific omitted VGA device.\n\tStatic Setup modifies '/etc/initramfs-tools/modules', '/etc/modules', and '/etc/modprobe.d/*.\n\tMulti-boot is the more flexible choice."

    if [[ -z $str_input1 ]]; then echo -e $str_prompt; fi

    while true; do

        if [[ $int_count -ge 3 ]]; then
            echo "$0: Exceeded max attempts."
            str_input1="N"                   # default selection
        else
            echo -en "$0: Setup VFIO? [ (M)ulti-Boot / (S)tatic / (N)one ]: "
            read -r str_input1
            str_input1=$(echo $str_input1 | tr '[:lower:]' '[:upper:]')
            str_input1=${str_input1:0:1}
        fi

        case $str_input1 in
            "M")
                echo -e "$0: Continuing with Multi-Boot setup...\n"

                #MultiBootSetup $bool_isVFIOsetup $str_GRUB_CMDLINE_Hugepages
                #StaticSetup $bool_isVFIOsetup $str_GRUB_CMDLINE_Hugepages
                MultiBootSetup $str_GRUB_CMDLINE_Hugepages
                StaticSetup $str_GRUB_CMDLINE_Hugepages

                #sudo update-grub                    # update GRUB
                #sudo update-initramfs -u -k all     # update INITRAMFS

                echo -e "$0: NOTE: Review changes in:\n\t'/etc/default/grub'\n\t'/etc/initramfs-tools/modules'\n\t'/etc/modules'\n\t/etc/modprobe.d/*"
                break;;

            "S")
                echo -e "$0: Continuing with Static setup...\n"

                #StaticSetup $bool_isVFIOsetup $str_GRUB_CMDLINE_Hugepages
                StaticSetup $str_GRUB_CMDLINE_Hugepages

                #sudo update-grub                    # update GRUB
                #sudo update-initramfs -u -k all     # update INITRAMFS

                echo -e "$0: NOTE: Review changes in:\n\t'/etc/default/grub'\n\t'/etc/initramfs-tools/modules'\n\t'/etc/modules'\n\t/etc/modprobe.d/*"
                break;;

            "N")
                echo -e "$0: Skipping...\n"
                exit 0;;

            *)
                echo "$0: Invalid input.";;
        esac
        ((int_count++))     # increment counter
    done
    #
done
# 
    
# prompt uninstall setup or exit #
if [[ $bool_isVFIOsetup == true ]]; then

    echo -e "$0: WARNING: System is already setup with VFIO Passthrough."
    #echo -e "$0: To continue with a new VFIO setup:\n\tExecute the 'Uninstall VFIO setup,'\n\tReboot the system,\n\tExecute '$0'."

    echo -en "$0: Uninstall VFIO setup on this system? [Y/n]: "
    ReadInput $str_input1

    case $str_input1 in
        "Y")
            #echo -e "$0: Uninstalling VFIO setup...\n"
            #UninstallMultiBootSetup
            #UninstallStaticSetup
            break;;

        "N")
            echo -e "$0: Skipping...\n"
            exit 0;;

        *)
            echo "$0: Invalid input.";;
    esac

    ((int_count++))     # increment counter
fi
#


exit 0