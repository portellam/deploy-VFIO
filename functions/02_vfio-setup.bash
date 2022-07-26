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

# input variables #
if [[ -e $2 ]]; then bool_isVFIOsetup=$2; fi
str_GRUB_CMDLINE_Hugepages=""

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

function StaticSetup {

    ## Parse PCI ##

    str_output1="$0: Parsing PCI device information... "
    echo -en $str_output1

    ## parameters ##
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
                    bool_isVFIOsetup=true
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
        #echo -e "$0: '$""str_lspci_busID' = '$str_lspci_busID'"                 # debug output

        # parse compgen info #
        for str_compgen in ${arr_compgen[@]}; do

            str_thisBusID=`echo $str_compgen | sort -h | cut -d '/' -f7`
            str_thisBusID=${str_thisBusID:5:10}                                 # valid element
            str_thisIOMMUID=`echo $str_compgen | sort -h | cut -d '/' -f5`      # valid element
            #echo -e "$0: '$""str_thisBusID' = '$str_thisBusID'"                 # debug output
            #echo -e "$0: '$""str_thisIOMMUID' = '$str_thisIOMMUID'"            # debug output

            # match Bus ID, add IOMMU ID at index #
            if [[ $str_thisBusID == $str_lspci_busID ]]; then
 
                arr_lspci_IOMMUID+=($str_thisIOMMUID)                           # add to list
                #echo "MATCH FOUND"
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

    echo -e "Complete."

    function debugOutput {

        #for (( i=0 ; i<${#arr_compgen[@]} ; i++ )); do echo -e "$0: '$""{arr_compgen[$i]}' = ${arr_compgen[$i]}"; done                             # debug output
        #for (( i=0 ; i<${#arr_compgen_busID[@]} ; i++ )); do echo -e "$0: '$""{arr_compgen_busID[$i]}' = ${arr_compgen_busID[$i]}"; done           # debug output
        #for (( i=0 ; i<${#arr_compgen_IOMMUID[@]} ; i++ )); do echo -e "$0: '$""{arr_compgen_IOMMUID[$i]}' = ${arr_compgen_IOMMUID[$i]}"; done     # debug output
        #for (( i=0 ; i<${#arr_lspci[@]} ; i++ )); do echo -e "$0: '$""{arr_lspci[$i]}' = ${arr_lspci[$i]}"; done                                   # debug output
        #for (( i=0 ; i<${#arr_lspci_busID[@]} ; i++ )); do echo -e "$0: '$""{arr_lspci_busID[$i]}' = ${arr_lspci_busID[$i]}"; done                 # debug output
        #for (( i=0 ; i<${#arr_lspci_deviceName[@]} ; i++ )); do echo -e "$0: '$""{arr_lspci_deviceName[$i]}' = ${arr_lspci_deviceName[$i]}"; done  # debug output
        #for (( i=0 ; i<${#arr_lspci_HWID[@]} ; i++ )); do echo -e "$0: '$""{arr_lspci_HWID[$i]}' = ${arr_lspci_HWID[$i]}"; done                    # debug output
        #for (( i=0 ; i<${#arr_lspci_type[@]} ; i++ )); do echo -e "$0: '$""{arr_lspci_type[$i]}' = ${arr_lspci_type[$i]}"; done                    # debug output
        #for (( i=0 ; i<${#arr_lspci_vendorName[@]} ; i++ )); do echo -e "$0: '$""{arr_lspci_vendorName[$i]}' = ${arr_lspci_vendorName[$i]}"; done  # debug output
        #for (( i=0 ; i<${#arr_lspci_driverName[@]} ; i++ )); do echo -e "$0: '$""{arr_lspci_driverName[$i]}' = ${arr_lspci_driverName[$i]}"; done  # debug output
        for (( i=0 ; i<${#arr_lspci_IOMMUID[@]} ; i++ )); do echo -e "$0: '$""{arr_lspci_IOMMUID[$i]}' = ${arr_lspci_IOMMUID[$i]}"; done           # debug output

        #echo -e "$0: '$""int_compgen_IOMMUID_lastIndex' = $int_compgen_IOMMUID_lastIndex"  # debug output
        #echo -e "$0: '$'""{#arr_compgen[@]} = ${#arr_compgen[@]}"                          # debug output
        #echo -e "$0: '$'""{#arr_compgen_busID[@]} = ${#arr_compgen_busID[@]}"              # debug output
        #echo -e "$0: '$'""{#arr_compgen_IOMMUID[@]} = ${#arr_compgen_IOMMUID[@]}"          # debug output
        #echo -e "$0: '$'""{#arr_lspci[@]} = ${#arr_lspci[@]}"                              # debug output
        #echo -e "$0: '$'""{#arr_lspci_busID[@]} = ${#arr_lspci_busID[@]}"                  # debug output
        #echo -e "$0: '$'""{#arr_lspci_deviceName[@]} = ${#arr_lspci_deviceName[@]}"        # debug output
        #echo -e "$0: '$'""{#arr_lspci_HWID[@]} = ${#arr_lspci_HWID[@]}"                    # debug output
        #echo -e "$0: '$'""{#arr_lspci_type[@]} = ${#arr_lspci_type[@]}"                    # debug output
        #echo -e "$0: '$'""{#arr_lspci_vendorName[@]} = ${#arr_lspci_vendorName[@]}"        # debug output
        #echo -e "$0: '$'""{#arr_lspci_driverName[@]} = ${#arr_lspci_driverName[@]}"        # debug output
        echo -e "$0: '$'""{#arr_lspci_IOMMUID[@]} = ${#arr_lspci_IOMMUID[@]}"              # debug output
    
    }

    #debugOutput    # uncomment to debug   

    ## end Parse PCI ##

    ## parameters ##
    # files #
    #str_file1="/etc/default/grub"
    #str_file2="/etc/initramfs-tools/modules"
    #str_file3="/etc/modules"
    #str_file4="/etc/modprobe.d/pci-blacklists.conf"
    #str_file5="/etc/modprobe.d/vfio.conf"
    #

    # debug logfiles #    
    str_file1=$(pwd)"/grub.log"
    str_file2=$(pwd)"/initramfs-modules.log"
    str_file3=$(pwd)"/modules.log"
    str_file4=$(pwd)"/pci-blacklists.conf.log"
    str_file5=$(pwd)"/vfio.conf.log"
    ##

    # clear files #     # NOTE: do NOT delete GRUB
    if [[ -e $str_file2 ]]; then rm $str_file2; fi
    if [[ -e $str_file3 ]]; then rm $str_file3; fi
    if [[ -e $str_file4 ]]; then rm $str_file4; fi
    if [[ -e $str_file5 ]]; then rm $str_file5; fi
    #

    # list IOMMU groups #
    str_output1="$0: PLEASE READ: PCI expansion slots may share 'IOMMU' groups. Therefore, PCI devices may share IOMMU groups.
    \n\tPLEASE READ: Devices that share IOMMU groups must be passed-through as whole or none at all.
    \n\tPLEASE READ: Evaluate order of PCI slots to have PCI devices in individual IOMMU groups.
    \n\tPLEASE READ: A feature (ACS-Override patch) exists to divide IOMMU groups, but said feature creates an attack vector (memory read/write across PCI devices) and is not recommended (for security reasons).
    \n\tPLEASE READ: Some onboard PCI devices may NOT share IOMMU groups. Example: a USB controller.\n\n$0: Review the output below before choosing which IOMMU groups (groups of PCI devices) to pass-through or not."

    echo -e $str_output1

    ## NOTE: fixed ParsePCI, left off here

    echo -e "$0: '$'""int_compgen_IOMMUID_lastIndex = $int_compgen_IOMMUID_lastIndex"   # debug output
    echo -e "$0: '$'""{arr_lspci_busID[1]} = ${arr_lspci_busID[1]}"                     # debug output

    # how to pass through variables into another function

    ##
    # parse list of PCI devices, in order of IOMMU ID #
    declare -i int_i=0          # reset counter
    
    while [[ $int_i -le $int_compgen_IOMMUID_lastIndex ]]; do

        echo -e "\n\t IOMMU ID: '${arr_lspci_IOMMUID[$int_i]}'"

        declare -i int_k=0      # reset counter

        #
        for (( int_j=0 ; int_j<${#arr_lspci_IOMMUID[@]} ; int_j++ )); do

            #
            if [[ $arr_lspci_IOMMUID[$int_j] == $int_i ]]; then

                # output #
                echo -e "\tDevice #1"
                echo -e "\tDeviceName: '${arr_lspci_deviceName[$int_j]}'"
                echo -e "\tType: '${arr_lspci_type[$int_j]}'"
                echo -e "\n\tBus ID: '${arr_lspci_busID[$int_j]}'"
                echo -e "\n\tHWID: '${arr_lspci_HWID[$int_j]}'"
                #

            fi
            #

            ((int_k++))         # increment counter

        done
        #

        ((int_i++))         # increment counter

    done
    ##

    # pre-setup:    -check for package dependencies
    # -parse by IOMMU group
    # -each device that exists in said group
    #   -hw id, driver name, device type
    #   -if driver name is invalid (null or vfio), note on screen (also boolean will notify user to quit script, undo vfio auto or later time)
    #   -if driver is valid, note vga
    #   -once group parse is complete, ask user if they wish to make (at the end) GRUB entries that include and one entry that excludes said group (if vga exists)
    # that should be it
    # also test ParsePCI
    # -shall i compare 'compgen' and 'lspci' by bus id, and save indexes from lspci to iommu groups?
    # -then reference all info from said indexes?
    # MULTI BOOT - output cmd lines and GRUB menu titles to logfile and console output, directions on how to update grub

    exit 0

    # parse list of PCI devices, in order of IOMMU ID #
    declare -i int_i=0      # reset counter

    while [[ $int_i -le $int_compgen_IOMMUID_lastIndex ]]; do

        echo -e
        declare -a arr_lspci_index_list=()      # reset array
        bool_hasExternalPCI=false               # reset boolean
        bool_hasExternalVGA=false               # reset boolean

        # parse list of IOMMU IDs (in no order) #
        declare -i int_j=0      # reset counter

        while [[ $int_j -le $int_compgen_IOMMUID_lastIndex ]]; do

            #echo -e "$0: int_j == '$int_j'"                                                # debug output
            #echo -e "$0: {arr_lspci_IOMMUID[$int_j]} == '"$arr_lspci_IOMMUID[$int_j]"'"    # debug output

            # match given IOMMU ID at given index #
            if [[ "$arr_lspci_IOMMUID[$int_j]" == "$int_i" ]]; then
                arr_lspci_index_list+=("$int_j")    # add new index to list
            fi      
            #

            # false match #
            if [[ "$arr_lspci_IOMMUID[$int_j]" != "$int_i" && $int_j -gt $int_i ]]; then
                break
            fi
            #

            echo -e "$0: {arr_lspci_index_list[$int_j]} == '"$arr_lspci_index_list[$int_j]"'"       # debug output

            ((int_j++))     # increment counter

        done
        #

        ((int_i++))         # increment counter

    done
    #

    while [[ $int_i -le $int_compgen_IOMMUID_lastIndex ]]; do

        echo -e
        declare -a arr_lspci_index_list=()      # reset array
        bool_hasExternalPCI=false               # reset boolean
        bool_hasExternalVGA=false               # reset boolean
        
        # parse list of IOMMU IDs (in no order) #
        declare -i int_j=0      # reset counter
        while [[ $int_j -le $int_compgen_IOMMUID_lastIndex ]]; do

            #echo -e "$0: int_j == '$int_j'"                                                 # debug output
            #echo -e "$0: {arr_lspci_IOMMUID[$int_j]} == '"$arr_lspci_IOMMUID[$int_j]"'"       # debug output

            # match given IOMMU ID at given index #
            if [[ "$arr_lspci_IOMMUID[$int_j]" == "$int_i" ]]; then arr_lspci_index_list+=("$int_j"); fi      # add new index to list


            if [[ "$arr_lspci_IOMMUID[$int_j]" != "$int_i" && $int_j -gt $int_i ]]; then break; fi

            echo -e "$0: {arr_lspci_index_list[$int_j]} == '"$arr_lspci_index_list[$int_j]"'"       # debug output

            ((int_j++))     # increment counter
        done
        #

        ## window of PCI devices in given IOMMU group ##
        #bool_VGA_IOMMU_{$int_i}=false

        # parse list of PCI devices in given IOMMU group #
        for int_PCI_index in $arr_lspci_index_list; do

            #str_thisPCI_busID=${arr_lspci_busID[$int_j]}     # error?
            str_thisPCI_busID=${arr_lspci_busID[$int_i]}

            echo -e "$0: str_thisPCI_busID == '$str_thisPCI_busID'"     # debug output
                
            # find Device Class ID, truncate first index if equal to zero (to convert to integer)
            if [[ "${str_thisPCI_busID:0:1}" == "0" ]]; then str_thisPCI_busID=${str_thisPCI_busID:1:1}
            else str_thisPCI_busID=${str_thisPCI_busID:0:2}; fi
            #

            #echo -e "$0: str_thisPCI_busID == '$str_thisPCI_busID'"     # debug output
                
            # match greater/equal to Device Class ID #1
            if [[ $str_thisPCI_busID -ge 1 ]]; then
                
                # add IOMMU group information to lists #
                str_PCI_IOMMU_Driver_list_{$int_i}+="${arr_lspci_driverName[$int_PCI_index]},"
                str_PCI_IOMMU_HWID_list_{$int_i}+="${arr_lspci_HWID[$int_PCI_index]},"
                bool_hasExternalPCI=true               # list contains external PCI
            fi
            #

            # is device external and is VGA #
            #echo -e "$0: ${arr_lspci_type[$int_PCI_index]} == '${arr_lspci_type[$int_PCI_index]}'"
            #echo -e "$0: $str_thisPCI_busID == '$str_thisPCI_busID'"
            str_index=$arr_index[$int_PCI_index]
            
            echo -e "$0: str_index == '$str_index'"

            #if [[ $str_thisPCI_busID -ge 1 && ${arr_lspci_type[$int_PCI_index]} == *"VGA"* ]]; then  
            if [[ $str_thisPCI_busID -ge 1 && $str_index == *"VGA"* ]]; then   
                str_VGA_IOMMU_DeviceName_{$int_i}=${arr_lspci_deviceName[$int_PCI_index]}
                bool_hasExternalVGA=true               # list contains external VGA
            fi;
            #

            # output #
            echo -e "\n\tBus ID: '${arr_lspci_busID[$int_PCI_index]}'"
            echo -e "\tDeviceName: '${arr_lspci_deviceName[$int_PCI_index]}'"
            echo -e "\tType: '${arr_lspci_type[$int_PCI_index]}'"
        done
        ##

        ## prompt ##
        declare -i int_count=0      # reset counter

        # match if list does not contain VGA #
        # do passthrough all devices #
        if [[ $bool_hasExternalVGA == false ]]; then
            echo -e "$0: IOMMU group ID '$int_i': no external VGA device(s) found."
            str_input1="Y"
        fi
        #

        # match if list does NOT contain external PCI #
        # do NOT passthrough all devices #
        if [[ $bool_hasExternalPCI == false ]]; then
            echo -e "$0: IOMMU group ID '$int_i': no external PCI device(s) found."
            str_input1="N"
        fi
        #

        # match if list does NOT contain external PCI #
        # do NOT passthrough all devices #
        if [[ $bool_hasExternalVGA == true ]]; then
            echo -e "$0: IOMMU group ID '$int_i': external VGA device(s) found."
            str_input1="N"
        fi
        # 

        while true; do

            if [[ $int_count -ge 3 ]]; then
                echo "$0: Exceeded max attempts."
                str_input1="N"                      # default selection        
            else
                echo -en "$0: Do you wish to pass-through IOMMU group ID '$int_i'? [Y/n]: "
                read -r str_input1
                str_input1=`echo $str_input1 | tr '[:lower:]' '[:upper:]'`
            fi

            case $str_input1 in
                "Y")
                    echo "$0: Passing-through IOMMU group ID '$int_i'."

                    # add IOMMU group to VFIO pass-through lists #
                    arr_lspci_driverName_list+=($arr_lspci_IOMMU_{$int_i}_Driver_list)
                    str_PCI_Driver_list+=$str_PCI_IOMMU_{$int_i}_Driver_list
                    str_PCI_HWID_list+=$str_PCI_IOMMU_{$int_i}_HWID_list
                    #
                    break;;
                "N")
                    echo "$0: Skipping IOMMU group ID '$int_i'."
                    break;;
                *)
                    echo "$0: Invalid input.";;
            esac

            ((int_count++))     # increment counter
        done

        ((int_i++))     # increment counter
    done
    #

    # remove last separator #
    if [[ ${str_PCI_Driver_list: -1} == "," ]]; then str_PCI_Driver_list=${str_PCI_Driver_list::-1}; fi

    if [[ ${str_PCI_HWID_list: -1} == "," ]]; then str_PCI_HWID_list=${str_PCI_HWID_list::-1}; fi
    #

    # VFIO soft dependencies #
    for str_thisPCI_Driver in $arr_lspci_driverName_list; do
        str_PCI_Driver_list_softdep="softdep $str_thisPCI_Driver pre: vfio-pci\n$str_thisPCI_Driver"
    done
    #

    ## GRUB ##
    bool_str_file1=false
    str_GRUB="GRUB_CMDLINE_DEFAULT=\"acpi=force apm=power_off iommu=1,pt amd_iommu=on intel_iommu=on rd.driver.pre=vfio-pci pcie_aspm=off kvm.ignore_msrs=1 $str_GRUB_CMDLINE_Hugepages modprobe.blacklist=$str_PCI_Driver_list vfio_pci.ids=$str_PCI_HWID_list\""

    # backup file
    if [[ -z $str_file1"_old" ]]; then cp $str_file1 $str_file1"_old"; fi
    #

    # find GRUB line and comment out #
    while read str_line_1; do

        # match line #
        if [[ $str_line_1 != *"GRUB_CMDLINE_DEFAULT"* && $str_line_1 != *"#GRUB_CMDLINE_DEFAULT"* ]]; then
            bool_str_file1=true
            str_line1=$str_GRUB                         # update line
        fi

        echo -e $str_line_1  >> $str_file1"_new"        # append to new file
    done < $str_file1
    #

    # no GRUB line found, append at end #
    if [[ $bool_str_file1 == false ]]; then echo -e "\n$str_GRUB"  >> $str_file1"_new"; fi
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
\n
# Soft dependencies and PCI kernel drivers:
$str_PCI_Driver_list_softdep
\nvfio
vfio_iommu_type1
vfio_virqfd
\n# GRUB command line and PCI hardware IDs:
options vfio_pci ids=$str_PCI_HWID_list
vfio_pci ids=$str_PCI_HWID_list
vfio_pci
# END #")

    for str_line1 in ${arr_file2[@]}; do echo -e $str_line1 >> $str_file2; done
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
#
vfio
vfio_iommu_type1
vfio_pci
vfio_virqfd
kvm
kvm_intel
apm power_off=1
\n# In terminal, execute \"lspci -nnk\".
\n# GRUB kernel parameters:
vfio_pci ids=$str_PCI_HWID_list
# END #")

    for str_line1 in ${arr_file3[@]}; do echo -e $str_line1 >> $str_file3; done
    ##

    ## /etc/modprobe.d/pci-blacklist.conf ##
    echo -e "# NOTE: Generated by 'portellam/VFIO-setup'\n# START #" >> $str_file4
    for str_thisPCI_Driver in $arr_lspci_driverName_list[@]; do
        echo -e "blacklist $str_thisPCI_Driver" >> $str_file4
    done
    echo -e "# END #" >> $str_file4
    ##

    ## /etc/modprobe.d/vfio.conf ##
    declare -a arr_file5=(
"# NOTE: Generated by 'portellam/VFIO-setup'
# START #
# NOTE: If you change this file, run 'update-initramfs -u -k all' afterwards to update.
# Soft dependencies:
$str_PCI_Driver_list_softdep
\n# PCI hardware IDs:
options vfio_pci ids=$str_PCI_HWID_list
# END #")
    for str_line1 in ${arr_file5[@]}; do echo -e $str_line1 >> $str_file5; done

}
## end StaticSetup ##

# check for hugepages logfile #
str_file0=`ls $(pwd) | grep -i 'hugepages' | grep -i '.log'ls $(pwd) | grep -i 'hugepages' | grep -i '.log'`
if [[ -z $str_file0 ]]; then
    echo -e "$0: Hugepages logfile does not exist. Should you wish to enable Hugepages, execute both '"`ls $(pwd) | grep -i 'hugepages' | grep -i '.bash'`"' and '$0'."
    str_GRUB_CMDLINE_Hugepages="default_hugepagesz=1G hugepagesz=1G hugepages="
else
    while read str_line1; do
        if [[ $str_line1 == *"hugepagesz="* ]]; then str_GRUB_CMDLINE_Hugepages+="default_$str_line1 $str_line1"; fi    # parse hugepage size
        if [[ $str_line1 == *"hugepages="* ]]; then str_GRUB_CMDLINE_Hugepages+="$str_line1"; fi                       # parse hugepage num
    done < $str_file0
fi
#

# prompt #
declare -i int_count=0      # reset counter
str_prompt="$0: Setup VFIO by 'Multi-Boot' or Statically?\n\tMulti-Boot Setup includes adding GRUB boot options, each with one specific omitted VGA device.\n\tStatic Setup modifies '/etc/initramfs-tools/modules', '/etc/modules', and '/etc/modprobe.d/*.\n\tMulti-boot is the more flexible choice."

if [[ -z $str_input1 ]]; then echo -e $str_prompt; fi

#while [[ $bool_isVFIOsetup == false || -z $bool_isVFIOsetup ]]; do
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
            #echo -e "$0: Skipping...\n"
            break;;
        *)
            echo "$0: Invalid input.";;
    esac
    ((int_count++))     # increment counter
done
#
    
# prompt uninstall setup or exit #
if [[ $bool_isVFIOsetup == true && -e $bool_isVFIOsetup ]]; then

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
            #echo -e "$0: Skipping...\n"
            break;;
        *)
            echo "$0: Invalid input.";;
    esac

    ((int_count++))     # increment counter
fi
#

IFS=$SAVEIFS        # reset IFS     # NOTE: necessary for newline preservation in arrays and files
echo "$0: Exiting."
exit 0