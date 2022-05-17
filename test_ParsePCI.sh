#!/bin/bash

function ParsePCI {

    while [[ $bool_VFIO_Setup == false ]]; do
 
    ## parsed lists ##
    # NOTE: all parsed lists should be same size/length, for easy recall

    declare -a arr_PCI_BusID=(`lspci -m | cut -d '"' -f 1`)       # ex '01:00.0'
    declare -a arr_PCI_DeviceName=(`lspci -m | cut -d '"' -f 6`)  # ex 'GP104 [GeForce GTX 1070]''
    declare -a arr_PCI_HW_ID=(`lspci -n | cut -d ' ' -f 3`)       # ex '10de:1b81'
    declare -a arr_PCI_IOMMU_ID
    declare -a arr_PCI_Type=(`lspci -m | cut -d '"' -f 2`)        # ex 'VGA compatible controller'
    declare -a arr_PCI_VendorName=(`lspci -m | cut -d '"' -f 4`)  # ex 'NVIDIA Corporation'

    # add empty values to pad out and make it easier for parse/recall
    declare -a arr_PCI_Driver                                   # ex 'nouveau' or 'nvidia'

    ##

    # unparsed list #
    declare -a arr_lspci_k=(`lspci -k | grep -Eiv 'DeviceName|Subsystem|modules'`)
    declare -a arr_compgen_G=(`compgen -G "/sys/kernel/iommu_groups/*/devices/*"`)

    ## parse IOMMU ##
    # parse list of Bus IDs #
    for (( int_i=0; int_i<${#arr_PCI_BusID[@]}; int_i++ )); do

        # reformat element
        arr_PCI_BusID[$int_i]=${arr_PCI_BusID[$int_i]::-1}

        # parse list of output (Bus IDs and IOMMU IDs) #
        for (( int_j=0; int_j<${#arr_compgen_G[@]}; int_j++ )); do

            # match output with Bus ID #
            # true, save IOMMU ID at given index, exit loop #
            if [[ ${arr_compgen_G[$int_j]} == *"${arr_PCI_BusID[$int_i]}"* ]]; then

                arr_PCI_IOMMU_ID[$int_i]=`echo ${arr_compgen_G[$int_j]} | cut -d '/' -f 5`
                declare -i int_j=${#arr_compgen_G}

            fi
            #

        done
        #

    done
    ##

    ## parse drivers ##
    # parse list of output (Bus IDs and drivers #
    for (( int_i=0; int_i<${#arr_lspci_k[@]}; int_i++ )); do

        str_line1=${arr_lspci_k[$int_i]}                                    # current line
        str_PCI_BusID=`echo $str_line1 | grep -Eiv 'driver'`                # valid element
        str_PCI_Driver=`echo $str_line1 | grep 'driver' | cut -d ' ' -f 5`  # valid element

        # driver is NOT null and Bus ID is null #
        # add to list 
        if [[ -z $str_PCI_BusID && ! -z $str_PCI_Driver && $str_PCI_Driver != 'vfio-pci' ]]; then

            arr_PCI_Driver+=("$str_PCI_Driver")
            
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

    #
    function debug {

      echo -e "$0: arr_PCI_BusID == ${#arr_PCI_BusID[@]}i"
        for element in ${arr_PCI_BusID[@]}; do
            echo -e "$0: arr_PCI_BusID == "$element
        done

        echo -e "$0: arr_PCI_DeviceName == ${#arr_PCI_DeviceName[@]}i"
        for element in ${arr_PCI_DeviceName[@]}; do
            echo -e "$0: arr_PCI_DeviceName == "$element
        done

        echo -e "$0: arr_PCI_Driver == ${#arr_PCI_Driver[@]}i"
        for element in ${arr_PCI_Driver[@]}; do
            echo -e "$0: arr_PCI_Driver == "$element
        done

        echo -e "$0: arr_PCI_HW_ID == ${#arr_PCI_HW_ID[@]}i"
        for element in ${arr_PCI_HW_ID[@]}; do
            echo -e "$0: arr_PCI_HW_ID == "$element
        done

        echo -e "$0: arr_PCI_IOMMU_ID == ${#arr_PCI_IOMMU_ID[@]}i"
        for element in ${arr_PCI_IOMMU_ID[@]}; do
            echo -e "$0: arr_PCI_IOMMU_ID == "$element
        done

        echo -e "$0: arr_PCI_Type == ${#arr_PCI_Type[@]}i"
        for element in ${arr_PCI_Type[@]}; do
            echo -e "$0: arr_PCI_Type == "$element
        done

        echo -e "$0: arr_PCI_VendorName == ${#arr_PCI_VendorName[@]}i"
        for element in ${arr_PCI_VendorName[@]}; do
            echo -e "$0: arr_PCI_VendorName == "$element
        done

    }
    
    #debug
    #

    done
    #

}

# set IFS #
SAVEIFS=$IFS   # Save current IFS (Internal Field Separator)
IFS=$'\n'      # Change IFS to newline char
#

# a canary boolean to stop script and warn user the current system is already VFIO setup.
# suggest a wipe of all VFIO setup (minus extras like Hugepages, Evdev, ZRAM, etc.), and reboot to continue.
bool_VFIO_Setup=false   

# execute setup #
while [[ $bool_VFIO_Setup == false ]]; do

    ParsePCI $bool_VFIO_Setup

done
#

# prompt uninstall setup or exit #
if [[ $bool_VFIO_Setup == true ]]; then

    echo -e "$0: Host system is already setup with VFIO Passthrough.\n$0: To continue with a new VFIO setup:\n\tExecute the 'Uninstall VFIO setup,'\n\tReboot the system,\n\tExecute '$0'."

    while [[ $bool_VFIO_Setup == true ]]; do
    
        if [[ $int_count -ge 3 ]]; then

            echo "$0: Exceeded max attempts."
            str_input1="N"      # default selection
        
        else

            echo -en "$0: Uninstall VFIO on this system? [ Y/n ]: "
            read -r str_input1
            str_input1=`echo $str_input1 | tr '[:lower:]' '[:upper:]'`

        fi

        case $str_input1 in

            "Y")
                echo -e "$0: Uninstalling VFIO setup...\n"
                #UninstallMultiBoot
                #UninstallStaticSetup
                break;;

            "N")
                echo -e "$0: Skipping...\n"
                break;;

            *)
                echo "$0: Invalid input.";;

        esac
        ((int_count++))

        done
        #
        

    done

fi
#

# reset IFS #
IFS=$SAVEIFS   # Restore original IFS
#

exit 0
