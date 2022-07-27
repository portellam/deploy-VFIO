#!/bin/bash sh

# check if sudo/root #
if [[ `whoami` != "root" ]]; then

    echo -e "$0: WARNING: Script must be run as Sudo or Root! Exiting."
    exit 0

fi
#

# NOTE: necessary for newline preservation in arrays and files #
SAVEIFS=$IFS   # Save current IFS (Internal Field Separator)
IFS=$'\n'      # Change IFS to newline char
#

bool_isVFIOsetup=false
# input variables #
str_GRUB_CMDLINE_Hugepages=""
#

## Parse PCI ##

echo -en "$0: Parsing PCI device information... "

## parameters ##
bool_hasExternalPCI=false 
bool_hasExternalVGA=false
bool_hasNoDriver=false
bool_hasVFIODriver=false

readonly int_compgen_IOMMUID_lastIndex=`compgen -G "/sys/kernel/iommu_groups/*/devices/*" | cut -d '/' -f5 | sort -hr | head -n1`       # IOMMU ID, sorted
declare -a arr_compgen=(`compgen -G "/sys/kernel/iommu_groups/*/devices/*" | sort -h`)                                                  # IOMMU ID and Bus ID, sorted by IOMMU ID (left-most digit)
declare -a arr_compgen_busID=(`compgen -G "/sys/kernel/iommu_groups/*/devices/*" | sort -h | cut -d '/' -f7`)                           # Bus ID, sorted by IOMMU ID (left-most digit) (ex '0001:00.0')
declare -a arr_compgen_IOMMUID=(`compgen -G "/sys/kernel/iommu_groups/*/devices/*" | sort -h | cut -d '/' -f5`)                         # IOMMU ID, sorted by IOMMU ID (left-most digit)
declare -a arr_lspci=(`lspci -k | grep -Eiv 'DeviceName|Subsystem|modules'`)        # dev name, Bus ID, and (sometimes) driver, sorted
declare -a arr_lspci_busID=(`lspci -m | cut -d '"' -f 1`)                           # Bus ID, sorted        (ex '01:00.0')              # same length as 'arr_compgen_busID'
declare -a arr_lspci_deviceName=(`lspci -m | cut -d '"' -f 6`)                      # dev name, sorted      (ex 'GP104 [GeForce GTX 1070]')
declare -a arr_lspci_HWID=(`lspci -n | cut -d ' ' -f 3`)                            # HW ID, sorted         (ex '10de:1b81')
declare -a arr_lspci_type=(`lspci -m | cut -d '"' -f 2`)                            # dev type, sorted      (ex 'VGA compatible controller')
declare -a arr_lspci_vendorName=(`lspci -m | cut -d '"' -f 4`)                      # ven name, sorted      (ex 'NVIDIA Corporation')

readonly arr_compgen
readonly arr_compgen_busID
readonly arr_compgen_IOMMUID
readonly arr_lspci
readonly arr_lspci_busID
readonly arr_lspci_deviceName
readonly arr_lspci_HWID
readonly arr_lspci_type
readonly arr_lspci_vendorName

declare -a arr_lspci_driverName     # driver name, sorted by Bus ID     (ex 'nouveau' or 'nvidia')
declare -a arr_lspci_IOMMUID        # strings of index(es) of every Bus ID and entry, sorted by IOMMU ID
##

## find and sort drivers by Bus ID (lspci) ##
# parse Bus ID #
for (( int_i=0 ; int_i<${#arr_lspci_busID[@]} ; int_i++ )); do

    bool_readNextLine=false
    str_thatBusID=${arr_lspci_busID[$int_i]}

    # parse lspci info #
    for str_line1 in ${arr_lspci[@]}; do

        # 1 #
        # match boolean and driver, add to list #
        if [[ $bool_readNextLine == true && $str_line1 == *"driver"* ]]; then

            str_thisDriverName=`echo $str_line1 | grep "driver" | cut -d ' ' -f5`

            # vfio driver found, note input, add to list and update boolean #
            if [[ $str_thisDriverName == 'vfio-pci' ]]; then

                str_thisDriverName="VFIO_DRIVER_FOUND"
                #bool_isVFIOsetup=true

            fi
            #

            arr_lspci_driverName+=($str_thisDriverName)
            bool_readNextLine=false
            str_thisBusID=""

        fi
        #

        # 1 #
        # match boolean and false match line, add to list, reset boolean #
        if [[ $bool_readNextLine == true && $str_line1 != *"driver"* ]]; then

            str_thisDriverName=("NO_DRIVER_FOUND")
            arr_lspci_driverName+=($str_thisDriverName)
            bool_readNextLine=false
            break

        fi

        # 2 #
        # match Bus ID, update boolean #
        if [[ $str_line1 == *$str_thatBusID* ]]; then

          bool_readNextLine=true

        fi
        #

    done
    #

done
##

## find and sort IOMMU IDs by Bus ID (lspci) ##
# parse list of Bus IDs #
for str_lspci_busID in ${arr_lspci_busID[@]}; do

    str_lspci_busID=${str_lspci_busID::-1}                                  # valid element

    # parse compgen info #
    for str_compgen in ${arr_compgen[@]}; do

        str_thisBusID=`echo $str_compgen | sort -h | cut -d '/' -f7`
        str_thisBusID=${str_thisBusID:5:10}                                 # valid element
        str_thisIOMMUID=`echo $str_compgen | sort -h | cut -d '/' -f5`      # valid element

        # match Bus ID, add IOMMU ID at index #

        if [[ $str_thisBusID == $str_lspci_busID ]]; then

            arr_lspci_IOMMUID+=($str_thisIOMMUID)                           # add to list
            break

        fi
        #

    done
    #

done
##

# parameters #
readonly arr_lspci_driverName
readonly arr_lspci_IOMMUID
#

echo -e "Complete.\n"

function debugOutput {

    #for (( i=0 ; i<${#arr_compgen[@]} ; i++ )); do echo -e "$0: '$""{arr_compgen[$i]}' = ${arr_compgen[$i]}"; done
    #for (( i=0 ; i<${#arr_compgen_busID[@]} ; i++ )); do echo -e "$0: '$""{arr_compgen_busID[$i]}' = ${arr_compgen_busID[$i]}"; done
    #for (( i=0 ; i<${#arr_compgen_IOMMUID[@]} ; i++ )); do echo -e "$0: '$""{arr_compgen_IOMMUID[$i]}' = ${arr_compgen_IOMMUID[$i]}"; done
    #for (( i=0 ; i<${#arr_lspci[@]} ; i++ )); do echo -e "$0: '$""{arr_lspci[$i]}' = ${arr_lspci[$i]}"; done
    #for (( i=0 ; i<${#arr_lspci_busID[@]} ; i++ )); do echo -e "$0: '$""{arr_lspci_busID[$i]}' = ${arr_lspci_busID[$i]}"; done
    #for (( i=0 ; i<${#arr_lspci_deviceName[@]} ; i++ )); do echo -e "$0: '$""{arr_lspci_deviceName[$i]}' = ${arr_lspci_deviceName[$i]}"; done
    #for (( i=0 ; i<${#arr_lspci_HWID[@]} ; i++ )); do echo -e "$0: '$""{arr_lspci_HWID[$i]}' = ${arr_lspci_HWID[$i]}"; done
    #for (( i=0 ; i<${#arr_lspci_type[@]} ; i++ )); do echo -e "$0: '$""{arr_lspci_type[$i]}' = ${arr_lspci_type[$i]}"; done
    #for (( i=0 ; i<${#arr_lspci_vendorName[@]} ; i++ )); do echo -e "$0: '$""{arr_lspci_vendorName[$i]}' = ${arr_lspci_vendorName[$i]}"; done
    for (( i=0 ; i<${#arr_lspci_driverName[@]} ; i++ )); do echo -e "$0: '$""{arr_lspci_driverName[$i]}' = ${arr_lspci_driverName[$i]}"; done
    #for (( i=0 ; i<${#arr_lspci_IOMMUID[@]} ; i++ )); do echo -e "$0: '$""{arr_lspci_IOMMUID[$i]}' = ${arr_lspci_IOMMUID[$i]}"; done
    #echo -e "$0: '$""int_compgen_IOMMUID_lastIndex' = $int_compgen_IOMMUID_lastIndex"
    #echo -e "$0: '$'""{#arr_compgen[@]} = ${#arr_compgen[@]}"
    #echo -e "$0: '$'""{#arr_compgen_busID[@]} = ${#arr_compgen_busID[@]}"
    #echo -e "$0: '$'""{#arr_compgen_IOMMUID[@]} = ${#arr_compgen_IOMMUID[@]}"
    #echo -e "$0: '$'""{#arr_lspci[@]} = ${#arr_lspci[@]}"
    #echo -e "$0: '$'""{#arr_lspci_busID[@]} = ${#arr_lspci_busID[@]}"
    #echo -e "$0: '$'""{#arr_lspci_deviceName[@]} = ${#arr_lspci_deviceName[@]}"
    #echo -e "$0: '$'""{#arr_lspci_HWID[@]} = ${#arr_lspci_HWID[@]}"
    #echo -e "$0: '$'""{#arr_lspci_type[@]} = ${#arr_lspci_type[@]}"
    #echo -e "$0: '$'""{#arr_lspci_vendorName[@]} = ${#arr_lspci_vendorName[@]}"
    #echo -e "$0: '$'""{#arr_lspci_driverName[@]} = ${#arr_lspci_driverName[@]}"
    #echo -e "$0: '$'""{#arr_lspci_IOMMUID[@]} = ${#arr_lspci_IOMMUID[@]}"

}

#debugOutput    # uncomment to debug here
## end Parse PCI ##

#exit 0         # uncomment to debug here

## user input ##
str_input1=""

# precede with echo prompt for input #
# ask user for input then validate #
function ReadInput {
    
    str_input1=$(echo $str_input1 | tr '[:lower:]' '[:upper:]')
    str_input1=${str_input1:0:1}
    ValidInput $str_input1 $str_output1
    
}

# validate input, ask again, default answer NO #
function ValidInput {

    declare -i int_count=0    # reset counter
    
    while true; do

        # passthru input variable if it is valid #
        if [[ $str_input1 == * ]]; then

            str_input1=$str_input1      # input variable
            break

        fi
        #

        # manual prompt #
        if [[ $int_count -ge 3 ]]; then     # auto answer

            echo -e "$0: Exceeded max attempts. "
            str_input1="N"      # default input     # NOTE: change here

        else

            echo -en $str_output1
            read str_input1

            # string to upper
            str_input1=$(echo $str_input1 | tr '[:lower:]' '[:upper:]')
            str_input1=${str_input1:0:1}
            #

        fi
        #

        case $str_input1 in

            "Y"|"N")
                break;;

            *)
                echo -e "$0: Invalid input.";;

        esac

        ((int_count++))   # increment counter

    done

}
##

# prompt uninstall setup or exit #
function UninstallPrompt {

    declare -i int_count=0      # reset counter

    while true; do

        # manual prompt #
        if [[ $int_count -ge 3 ]]; then     # auto answer

            echo -e "$0: Exceeded max attempts."
            str_input1="N"      # default input     # NOTE: change here

        else

            str_output1="$0: Uninstall to continue? [Y/n]: "
            echo -en "\n$0: WARNING: Script has detected an existing VFIO Setup.\n$str_output1"
            read str_input1
            ReadInput $str_input1 $str_output1

        fi

        case $str_input1 in

            "Y")

                echo -en "$0: Uninstalling VFIO setup... "
                #UninstallMultiBootSetup
                #UninstallStaticSetup
                echo -e "Complete.\n\n$0: Reboot machine and execute script again to continue. Exiting."
                exit 0;;

            "N")

                echo -e "$0: Exiting."
                exit 0;;

            *)
                echo -e "$0: Invalid input.";;

        esac

        ((int_count++))     # increment counter

    done

}

function StaticSetup {

    ## parameters ##
    
    # files #
    str_file1="/etc/default/grub"
    str_file2="/etc/initramfs-tools/modules"
    str_file3="/etc/modules"
    str_file4="/etc/modprobe.d/pci-blacklists.conf"
    str_file5="/etc/modprobe.d/vfio.conf"
    #

    # debug logfiles #    
    str_logFile1=$(pwd)"/grub.log"
    str_logFile2=$(pwd)"/initramfs-modules.log"
    str_logFile3=$(pwd)"/modules.log"
    str_logFile4=$(pwd)"/pci-blacklists.conf.log"
    str_logFile5=$(pwd)"/vfio.conf.log"
    ##

    # clear logfiles #
    if [[ -e $str_logFile1 ]]; then rm $str_logFile1; fi
    if [[ -e $str_logFile2 ]]; then rm $str_logFile2; fi
    if [[ -e $str_logFile3 ]]; then rm $str_logFile3; fi
    if [[ -e $str_logFile4 ]]; then rm $str_logFile4; fi
    if [[ -e $str_logFile5 ]]; then rm $str_logFile5; fi
    #

    # list IOMMU groups #
    str_output1="$0: PLEASE READ: PCI expansion slots may share 'IOMMU' groups. Therefore, PCI devices may share IOMMU groups.
    \n\tPLEASE READ: Devices that share IOMMU groups must be passed-through as whole or none at all.
    \n\tPLEASE READ: Evaluate order of PCI slots to have PCI devices in individual IOMMU groups.
    \n\tPLEASE READ: A feature (ACS-Override patch) exists to divide IOMMU groups, but said feature creates an attack vector (memory read/write across PCI devices) and is not recommended (for security reasons).
    \n\tPLEASE READ: Some onboard PCI devices may NOT share IOMMU groups. Example: a USB controller.\n\n$0: Review the output below before choosing which IOMMU groups (groups of PCI devices) to pass-through or not.\n"

    echo -e $str_output1
    
    ## display each device in a given IOMMU group ##
    declare -i int_i=0          # reset counter

    # parse IOMMU IDs #
    while [[ $int_i -le $int_compgen_IOMMUID_lastIndex ]]; do

        echo -e "$0: IOMMU Group ID: $int_i"
        declare -i int_k=0                      # reset counter
        
        # parse IOMMU IDs #
        for (( int_j=0 ; int_j<${#arr_lspci_IOMMUID[@]} ; int_j++ )); do

            #
            if [[ ${arr_lspci_IOMMUID[$int_j]} == $int_i ]]; then

                str_thisBusID=${arr_lspci_busID[$int_j]}
                str_thisBusID=${str_thisBusID::-1}                  # valid element
                str_thisDriverName=${arr_lspci_driverName[$int_j]}  # valid element
                str_thisHWID=${arr_lspci_HWID[$int_j]}              # valid element

                ## checks ##
                if [[ ${str_thisBusID:1:1} -ge 1 ]]; then

                    bool_hasExternalPCI=true

                fi

                if [[ ${arr_lspci_type[$int_j]} == *"VGA"* ]]; then

                    bool_hasExternalVGA=true

                fi

                # if VFIO setup exists, clear strings and quit #
                if [[ ${arr_lspci_driverName[$int_j]} == "VFIO_DRIVER_FOUND" || $bool_hasVFIODriver == true ]]; then

                    bool_hasVFIODriver=true
                    str_driverName_tempList=""
                    str_HWID_tempList=""
                    arr_driverName_list=""

                fi

                if [[ ${arr_lspci_driverName[$int_j]} == "NO_DRIVER_FOUND" ]]; then

                    bool_hasNoDriver=true
                    str_thisDriverName=""
                    str_thisHWID=""

                fi
                ##

                # NOTE: last few IOMMU groups missing, otherwise data is correct
                # output #
                echo -e "\tINDEX:\t\t$int_k"
                echo -e "\tVENDOR:\t\t${arr_lspci_vendorName[$int_j]}"
                echo -e "\tDEVICE:\t\t${arr_lspci_deviceName[$int_j]}"
                echo -e "\tTYPE:\t\t${arr_lspci_type[$int_j]}"
                echo -e "\tBUS ID:\t\t$str_thisBusID"
                echo -e "\tHW ID:\t\t${arr_lspci_HWID[$int_j]}"
                echo -e "\tDRIVER:\t\t${arr_lspci_driverName[$int_j]}"
                #

                # add to list #

                if [[ $str_thisDriverName != "" && $str_thisHWID != "" ]]; then

                    str_driverName_tempList+="$str_thisDriverName,"
                    str_HWID_tempList+="$str_thisHWID,"
                    arr_driverName_list+=($str_thisDriverName)

                fi
                #

                ((int_k++)) # increment counter
            fi
            #

        done
        #

        ## prompt ##
        echo
        declare -i int_count=0      # reset counter

        # match if list does not contain VGA #
        # do passthrough all devices #
        if [[ $bool_hasExternalVGA == false ]]; then

            echo -e "$0: No VGA devices found."
            str_input1="Y"

        # match if list does contain VGA #
        else

            echo -e "$0: VGA devices found."
            str_input1="N"

        fi
        #

        # match if list does NOT contain external PCI #
        # do NOT passthrough all devices #
        if [[ $bool_hasExternalPCI == false ]]; then

            echo -e "$0: No external PCI devices found. Skipping prompt."
            str_input1="N"

        # match if list does contain external PCI #
        else

            echo -e "$0: External PCI devices found."
            str_input1="Y"

        fi
        #

        if [[ $bool_hasVFIODriver == true ]]; then

            echo -e "$0: WARNING: VFIO driver found."
            str_input1="N"
            bool_isVFIOsetup=true
            UninstallPrompt $bool_isVFIOsetup

        fi
        #

        echo

        while [[ $bool_hasExternalPCI == true ]]; do

            if [[ $int_count -ge 3 ]]; then

                echo "$0: Exceeded max attempts."
                str_input1="N"                      # default selection

            else

                echo -en "$0: Do you wish to pass-through IOMMU group '$int_i'? [Y/n]: "
                read -r str_input1
                str_input1=`echo $str_input1 | tr '[:lower:]' '[:upper:]'`

            fi

            case $str_input1 in

                "Y")
                
                    echo "$0: Passing-through IOMMU group '$int_i'."

                    # add IOMMU group to VFIO pass-through lists #
                    str_driverName_list+=$str_driverName_tempList
                    str_HWID_list+=$str_HWID_tempList
                    #
                    break;;

                "N")

                    #echo "$0: Skipping IOMMU group '$int_i'."
                    break;;

                *)
                    echo "$0: Invalid input.";;
            esac

            ((int_count++))                     # increment counter
        done

        bool_hasExternalPCI=false               # reset boolean
        bool_hasExternalVGA=false               # reset boolean
        bool_hasNoDriver=false                  # reset boolean
        bool_hasVFIODriver=false                # reset boolean
        str_driverName_tempList=""              # reset list
        str_HWID_tempList=""                    # reset list
        ((int_i++))                             # increment counter

    done
    ##

    # remove last separator #
    if [[ ${str_driverName_list: -1} == "," ]]; then

        str_driverName_list=${str_driverName_list::-1}

    fi

    if [[ ${str_HWID_list: -1} == "," ]]; then

        str_HWID_list=${str_HWID_list::-1}

    fi
    #

    # VFIO soft dependencies #
    for str_thisDriverName in ${arr_driverName_list[@]}; do

        echo "$0: 'str_thisDriverName' == $str_thisDriverName"
        str_driverName_list_softdep+="\nsoftdep $str_thisDriverName pre: vfio-pci\n$str_thisDriverName"

    done
    #

    ## GRUB ##
    bool_str_file1=false
    str_GRUB="GRUB_CMDLINE_DEFAULT=\"acpi=force apm=power_off iommu=1,pt amd_iommu=on intel_iommu=on rd.driver.pre=vfio-pci pcie_aspm=off kvm.ignore_msrs=1 $str_GRUB_CMDLINE_Hugepages modprobe.blacklist=$str_driverName_list vfio_pci.ids=$str_HWID_list\""

    # backup file
    if [[ -z $str_file1"_old" ]]; then cp $str_file1 $str_file1"_old"; fi
    #

    # find GRUB line and comment out #
    while read str_line1; do

        # match line #
        if [[ $str_line1 != *"GRUB_CMDLINE_DEFAULT"* && $str_line1 != *"#GRUB_CMDLINE_DEFAULT"* ]]; then

            bool_str_file1=true
            str_line1=$str_GRUB                         # update line

        fi

        echo -e $str_line1  >> $str_file1"_new"        # append to new file
        echo -e $str_line1  >> $str_logFile1           # append to log file

    done < $str_file1
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
"# NOTE: Generated by 'portellam/VFIO-setup'
# START #
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
# NOTE: In terminal, execute \"lspci -nnk\" or review the logfiles.
\n# Soft dependencies and PCI kernel drivers:$str_driverName_list_softdep
#
\n# NOTE: Do not change the following lines, unless you know what you are doing!
vfio
vfio_iommu_type1
vfio_virqfd
#
\n# GRUB command line and PCI hardware IDs:
options vfio_pci ids=$str_HWID_list
vfio_pci ids=$str_HWID_list
vfio_pci
#
# END #")

    for str_line1 in ${arr_file2[@]}; do

        echo -e $str_line1 >> $str_file2
        echo -e $str_line1 >> $str_logFile2

    done
    ##

    ## /etc/modules ##
    declare -a arr_file3=(
"# NOTE: Generated by 'portellam/VFIO-setup'
# START #
# /etc/modules: kernel modules to load at boot time.
#
# This file contains the names of kernel modules that should be loaded
# at boot time, one per line. Lines beginning with \"#\" are ignored.
#
# NOTE: GRUB command line is an easier and cleaner method if vfio-pci grabs all hardware.
# Example: Reboot hypervisor (Linux) to swap host graphics (Intel, AMD, NVIDIA) by use-case (AMD for Win XP, NVIDIA for Win 10).
# NOTE: If you change this file, run 'update-initramfs -u -k all' afterwards to update.
# NOTE: In terminal, execute \"lspci -nnk\" or review the logfiles.
#
\n# NOTE: Do not change the following lines, unless you know what you are doing!
vfio
vfio_iommu_type1
vfio_pci
vfio_virqfd
kvm
kvm_intel
apm power_off=1
#
\n# GRUB kernel parameters:
vfio_pci ids=$str_HWID_list
#
# END #")

    for str_line1 in ${arr_file3[@]}; do

        echo -e $str_line1 >> $str_file3
        echo -e $str_line1 >> $str_logFile3

    done
    ##

    ## /etc/modprobe.d/pci-blacklist.conf ##
    echo -e "# NOTE: Generated by 'portellam/VFIO-setup'\n# START #" >> $str_file4

    for str_thisDriverName in ${arr_driverName_list[@]}; do

        echo -e "blacklist $str_thisDriverName" >> $str_file4
        echo -e "blacklist $str_thisDriverName" >> $str_logFile4

    done

    echo -e "# END #" >> $str_file4
    ##

    ## /etc/modprobe.d/vfio.conf ##
    declare -a arr_file5=(
"# NOTE: Generated by 'portellam/VFIO-setup'
# START #
# NOTE: If you change this file, run 'update-initramfs -u -k all' afterwards to update.
# NOTE: In terminal, execute \"lspci -nnk\" or review the logfiles.
\n# Soft dependencies:$str_driverName_list_softdep
#
\n# PCI hardware IDs:
options vfio_pci ids=$str_HWID_list
# END #")

    for str_line1 in ${arr_file5[@]}; do

        echo -e $str_line1 >> $str_file5
        echo -e $str_line1 >> $str_logFile5

    done

}
## end StaticSetup ##

# check for hugepages logfile #
str_file0=`ls $(pwd) | grep -i 'hugepages' | grep -i '.log'`

if [[ -z $str_file0 ]]; then

    echo -e "$0: Hugepages logfile does not exist. Should you wish to enable Hugepages, execute both '"`ls $(pwd) | grep -i 'hugepages' | grep -i '.bash'`"' and '$0'.\n"
    str_GRUB_CMDLINE_Hugepages="default_hugepagesz=1G hugepagesz=1G hugepages="

else

    while read str_line1; do

        if [[ $str_line1 == *"hugepagesz="* ]]; then str_GRUB_CMDLINE_Hugepages+="default_$str_line1 $str_line1 "; fi    # parse hugepage size
        if [[ $str_line1 == *"hugepages="* ]]; then str_GRUB_CMDLINE_Hugepages+="$str_line1"; fi                       # parse hugepage num

    done < $str_file0

fi
#

# prompt #
declare -i int_count=0      # reset counter
str_prompt="$0: Setup VFIO by 'Multi-Boot' or Statically?\n\tMulti-Boot Setup includes adding GRUB boot options, each with one specific omitted VGA device.\n\tStatic Setup modifies '/etc/initramfs-tools/modules', '/etc/modules', and '/etc/modprobe.d/*.\n\tMulti-boot is the more flexible choice.\n"

if [[ -z $str_input1 ]]; then echo -e $str_prompt; fi

while [[ $bool_isVFIOsetup == false || -z $bool_isVFIOsetup ]]; do
#while true; do

    if [[ $int_count -ge 3 ]]; then

        echo -e "$0: Exceeded max attempts."
        str_input1="N"                   # default selection

    else

        echo -en "$0: Setup VFIO? [ (M)ulti-Boot / (S)tatic / (N)one ]: "
        read -r str_input1
        str_input1=$(echo $str_input1 | tr '[:lower:]' '[:upper:]')
        str_input1=${str_input1:0:1}

    fi

    case $str_input1 in

        "M")

            echo -e "$0: Executing Multi-Boot setup...\n"

            #MultiBootSetup $bool_isVFIOsetup $str_GRUB_CMDLINE_Hugepages
            #StaticSetup $bool_isVFIOsetup $str_GRUB_CMDLINE_Hugepages
            MultiBootSetup $str_GRUB_CMDLINE_Hugepages $bool_isVFIOsetup
            StaticSetup $str_GRUB_CMDLINE_Hugepages $bool_isVFIOsetup

            #sudo update-grub                    # update GRUB
            #sudo update-initramfs -u -k all     # update INITRAMFS

            echo -e "\n$0: Review changes in:\n\t'/etc/default/grub'\n\t'/etc/initramfs-tools/modules'\n\t'/etc/modules'\n\t/etc/modprobe.d/*"
            break;;

        "S")

            echo -e "$0: Executing Static setup...\n"

            #StaticSetup $bool_isVFIOsetup $str_GRUB_CMDLINE_Hugepages
            StaticSetup $str_GRUB_CMDLINE_Hugepages $bool_isVFIOsetup

            #sudo update-grub                    # update GRUB
            #sudo update-initramfs -u -k all     # update INITRAMFS

            echo -e "\n$0: Review changes in:\n\t'/etc/default/grub'\n\t'/etc/initramfs-tools/modules'\n\t'/etc/modules'\n\t/etc/modprobe.d/*"
            break;;

        "N")

            break;;

        *)

            echo -e "$0: Invalid input.";;

    esac

    ((int_count++))     # increment counter

done
#

IFS=$SAVEIFS        # reset IFS     # NOTE: necessary for newline preservation in arrays and files
echo -e "$0: Exiting."