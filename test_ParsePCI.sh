#!/bin/bash

function ParsePCI {
 
    ## parsed lists ##
    # TODO: input parameters, do I need to remove declarations?
    # NOTE: all parsed lists should be same size/length, for easy recall

    declare -a arr_PCI_BusID=`lspci -m | cut -d '"' -f 1`       # ex '01:00.0'
    declare -a arr_PCI_DeviceName=`lspci -m | cut -d '"' -f 6`  # ex 'GP104 [GeForce GTX 1070]''
    declare -a arr_PCI_HW_ID=`lspci -n | cut -d ' ' -f 3`       # ex '10de:1b81'
    declare -a arr_PCI_IOMMU_ID
    declare -a arr_PCI_Type=`lspci -m | cut -d '"' -f 2`        # ex 'VGA compatible controller'
    declare -a arr_PCI_VendorName=`lspci -m | cut -d '"' -f 4`  # ex 'NVIDIA Corporation'

    # add empty values to pad out and make it easier for parse/recall
    declare -a arr_PCI_Driver                                   # ex 'nouveau' or 'nvidia'

    ##

    # unparsed list #
    declare -a arr_lspci_k=`lspci -k | grep -Eiv 'DeviceName|Subsystem|modules'`
    declare -a arr_compgen_G=`compgen -G "/sys/kernel/iommu_groups/*/devices/*"`
    #

    # parse IOMMU #
    # parse list of Bus IDs
    for (( int_i=0; int_i<${arr_PCI_BusID[@]}; int_i++ )); do

        # parse list of output (Bus IDs and IOMMU IDs) 
        for (( int_j=0; int_j<${arr_compgen_G[@]}; int_j++ )); do

            # match output with Bus ID #
            # true, save IOMMU ID at given index #
            if [[ ${arr_compgen_G[$int_j]} == *"${arr_PCI_BusID[$int_i]}"* ]]; then

                arr_PCI_IOMMU_ID[$int_i]=`echo $str_line1 | cut -d '/' -f 5`
                int_j=${#arr_compgen_G[@]}

            fi

        done
        #

        # false match, save empty entry at given index #
        if [[ -z arr_PCI_IOMMU_ID[$int_i] ]]; then

            arr_PCI_IOMMU_ID[$int_i]=""
        
        fi
        #

    done
    #

    
    # parse drivers #
    declare -i int_i=0

    # parse list of output (Bus IDs and drivers)
    for str_line1 in $arr_lspci_k[@]; do

        # find driver #
        str_PCI_Driver=`echo $str_line1 | cut -d ' ' -f 5`

        # match current line with 'valid' driver #
        # true, save driver at given index #
        if [[ bool_parseNextLine == true && $str_line1 == *"driver"* && $str_PCI_Driver != "vfio-pci" ]]; then

            arr_PCI_Driver[$int_i]=$str_PCI_Driver
            bool_parseNextLine=false

        # false, save empty entry at given index #
        else

            arr_PCI_Driver[$int_i]=""
            bool_parseNextLine=false

        fi
        #

        # parse list of Bus IDs #
        while [[ $bool_parseNextLine == false && $int_i -lt ${#arr_PCI_BusID[@]} ]]; do

            str_line2=${arr_PCI_BusID[$int_i]}   # current line

            # match current line with Bus ID #
            # true, parse next line #
            if [[ $str_line1 == *"$str_line2"* && bool_parseNextLine == false ]]; then

                ((int_i++))
                bool_parseNextLine=true

            fi
            #

        done
        #

    done
    #

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
    
    debug
    #

}

# set IFS #
SAVEIFS=$IFS   # Save current IFS (Internal Field Separator)
IFS=$'\n'      # Change IFS to newline char
#

ParsePCI

# reset IFS #
IFS=$SAVEIFS   # Restore original IFS
#

exit 0
