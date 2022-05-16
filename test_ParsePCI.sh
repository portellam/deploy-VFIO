#!/bin/bash

 function ParsePCI {
 
    ## parsed lists ##
    # TODO: input parameters, do I need to remove declarations?
    # NOTE: all parsed lists should be same size/length, for easy recall

    declare -a arr_PCIBusID=`lspci -m | cut -d '"' -f 1`        # ex '01:00.0'
    declare -a arr_PCIDeviceName=`lspci -m | cut -d '"' -f 6`   # ex 'GP104 [GeForce GTX 1070]''
    declare -a arr_PCIHWID=`lspci -n | cut -d ' ' -f 3`         # ex '10de:1b81'
    declare -a arr_PCIType=`lspci -m | cut -d '"' -f 2`         # ex 'VGA compatible controller'
    declare -a arr_PCIVendorName=`lspci -m | cut -d '"' -f 4`   # ex 'NVIDIA Corporation'

    # add empty values to pad out and make it easier for parse/recall
    declare -a arr_listPCIDriver                                # ex 'nouveau' or 'nvidia'

    ##

    # unparsed list #
    declare -a arr_lspci_k=`lspci -k | grep -Eiv 'DeviceName|Subsystem|modules'`
    #

    # parse list of output (Bus IDs and drivers)
    declare -i int_i=0

    for str_line1 in $arr_lspci_k[@]; do

        # find driver #
        str_PCIDriver=`echo $str_line1 | cut -d ' ' -f 5`

        # match current line with 'valid' driver #
        # true, save driver to given index for parsing later #
        if [[ bool_parseNextLine == true && $str_line1 == *"driver"* && $str_PCIDriver != "vfio-pci" ]]; then

            arr_PCIDriver[$int_i]=$str_PCIDriver
            bool_parseNextLine=false

        # false, save empty entry to given index #
        else

            arr_PCIDriver[$int_i]=""
            bool_parseNextLine=false

        fi
        #

        # parse list of Bus IDs #
        while [[ $bool_parseNextLine == false && $int_i -lt ${#arr_PCIBusID[@]} ]]

            str_line2=${arr_PCIBusID[$int_i]}   # current line

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

 }
