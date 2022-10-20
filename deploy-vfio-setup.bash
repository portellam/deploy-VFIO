#!/bin/bash sh

##
## Author(s):    Alex Portell <github.com/portellam>
##

##
## TO-DO:
##  -organize error codes
##  -reduce redundant code
##  -separate concerns: for example, error code exits (pass or fail), and error code exceptions (specific details). Call these funcs separately.
##

# NOTE: necessary for exit code preservation for conditional statements
declare -i int_thisExitCode=$?

## prep and I/O functions ##
    function CheckIfUserIsRoot
    {
        if [[ $( whoami ) != "root" ]]; then
            str_thisFile=$( echo ${0##/*} )
            str_thisFile=$( echo $str_thisFile | cut -d '/' -f2 )
            echo -e "\e[33mWARNING:\e[0m"" Script must execute as root. In terminal, run:\n\t'sudo bash $str_thisFile'"

            # call functions
            SaveThisExitCode
            ExitWithThisExitCode
        fi
    }

    function CheckIfFileOrDirExists
    {
        echo -en "Checking if file or directory exists... "

        # null exception
        if [[ -z $1 ]]; then
            (exit 254)
        fi

        # dir/file not found
        if [[ ! -e $1 ]]; then
            find . -name $1 | uniq &> /dev/null || (exit 250)
        fi

        # call functions
        SaveThisExitCode
        EchoPassOrFailThisExitCode
        ParseThisExitCode
    }

    function CreateBackupFromFile
    {
        # behavior:
        #   create a backup file
        #   return boolean, to be used by main
        #

        echo -en "Backing up file... "

        # parameters
        str_thisFile=$1

        # create false match statements before work begins, to catch exceptions
        # null exception
        if [[ -z $str_thisFile ]]; then
            (exit 254)

        # file not found exception
        elif [[ ! -e $str_thisFile ]]; then
            (exit 250)

        # file not readable exception
        elif [[ ! -r $str_thisFile ]]; then
            (exit 249)

        # work
        else
            if [[ $int_thisExitCode -eq 0 ]]; then

                # parameters
                declare -r str_suffix=".old"
                declare -r str_thisDir=$( dirname $1 )
                declare -ar arr_thisDir=( $( ls -1v $str_thisDir | grep $str_thisFile | grep $str_suffix | uniq ) )

                # positive non-zero count
                if [[ "${#arr_thisDir[@]}" -ge 1 ]]; then

                    # parameters
                    declare -ir int_maxCount=5
                    str_line=${arr_thisDir[0]}
                    str_line=${str_line%"${str_suffix}"}        # substitution
                    str_line=${str_line##*.}                    # ditto

                    # check if string is a valid integer
                    if [[ "${str_line}" -eq "$(( ${str_line} ))" ]] 2> /dev/null; then
                        declare -ir int_firstIndex="${str_line}"

                    else
                        (exit 254)
                    fi

                    for str_element in ${arr_thisDir[@]}; do
                        if cmp -s $str_thisFile $str_element; then
                            (exit 131)
                            break
                        fi
                    done

                    # if latest backup is same as original file, exit
                    if cmp -s $str_thisFile ${arr_thisDir[-1]}; then
                        (exit 131)
                    fi

                    # before backup, delete all but some number of backup files
                    while [[ ${#arr_thisDir[@]} -ge $int_maxCount ]]; do
                        if [[ -e ${arr_thisDir[0]} ]]; then
                            rm ${arr_thisDir[0]}
                            break
                        fi
                    done

                    # if *first* backup is same as original file, exit
                    if cmp -s $str_thisFile ${arr_thisDir[0]}; then
                        (exit 131)
                    fi

                    # new parameters #
                    str_line=${arr_thisDir[-1]%"${str_suffix}"}     # substitution
                    str_line=${str_line##*.}                        # ditto

                    # check if string is a valid integer
                    if [[ "${str_line}" -eq "$(( ${str_line} ))" ]] 2> /dev/null; then
                        declare -i int_lastIndex="${str_line}"

                    else
                        (exit 254)
                    fi

                    (( int_lastIndex++ ))           # counter

                    # source file is newer and different than backup, add to backups
                    if [[ $str_thisFile -nt ${arr_thisDir[-1]} && ! ( $str_thisFile -ef ${arr_thisDir[-1]} ) ]]; then
                        cp $str_thisFile "${str_thisFile}.${int_lastIndex}${str_suffix}"

                    elif [[ $str_thisFile -ot ${arr_thisDir[-1]} && ! ( $str_thisFile -ef ${arr_thisDir[-1]} ) ]]; then
                        (exit 131)

                    else
                        (exit 131)
                    fi

                # no backups, create backup
                else
                    cp $str_thisFile "${str_thisFile}.0${str_suffix}"
                fi
            fi
        fi

        # call functions
        SaveThisExitCode
        EchoPassOrFailThisExitCode
        ParseThisExitCode

        # append output and return code
        case $int_thisExitCode in
            131)
                echo -e "No changes from most recent backup."
        esac
    }

    function CreateFile
    {
        echo -en "Creating file... "

        # null exception
        if [[ -z $1 ]]; then
            (exit 254)
        fi

        # file not found
        if [[ ! -e $1 ]]; then
            touch $1 &> /dev/null || (exit 250)

        else
            (exit 131)
        fi

        # call functions
        SaveThisExitCode
        EchoPassOrFailThisExitCode
        ParseThisExitCode
    }

    function DeleteFile
    {
        echo -en "Deleting file... "

        # null exception
        if [[ -z $1 ]]; then
            (exit 254)
        fi

        # file not found
        if [[ ! -e $1 ]]; then
            (exit 131)

        else
            rm $1 &> /dev/null || (exit 255)
        fi

        # call functions
        SaveThisExitCode
        EchoPassOrFailThisExitCode
        ParseThisExitCode
    }

    function EchoPassOrFailThisExitCode
    {
        # output a pass or fail depending on the exit code

        #
        # reserved/unreserved exit codes #
        #
        #   0       == always pass
        #   3       == free
        #   131-255 == free
        #

        if [[ ! -z $1 ]]; then
            echo -en "$1"
        fi

        # append output
        case "$int_thisExitCode" in
            0|3)
                echo -e " \e[32mSuccessful. \e[0m";;

            131)
                echo -e " \e[33mSkipped. \e[0m";;

            *)
                echo -e " \e[31mFailed. \e[0m";;
        esac
    }

    function ExitWithThisExitCode
    {
        echo -e "Exiting."
        exit $int_thisExitCode
    }

    function ParseThisExitCode
    {
        # output a specific error/exception given exit code

        #
        # relative exit codes
        #
        #   3       == pass with some errors
        #   255-248 == specified
        #   <= 247  == function specific
        #

        if [[ ! -z $1 ]]; then
            echo -en "$1"
        fi

        # append output
        case $int_thisExitCode in
            255)
                echo;;      # unspecified error

            254)
                echo -e "Exception: Null input.";;

            253)
                echo -e "Exception: Invalid input.";;

            252)
                echo -e "Error: Missed steps; missed execution of key subfunctions.";;

            251)
                echo -e "Error: Missing components/variables.";;

            250)
                echo -e "Exception: File/Dir does not exist.";;

            249)
                echo -e "Exception: File/Dir is not readable.";;

            248)
                echo -e "Exception: File/Dir is not writable.";;

            *)
                echo;;
        esac
    }

    function ReadFile
    {
        echo -en "Reading file... "

        # null exception
        if [[ -z $1 ]]; then
            (exit 254)
        fi

        # file not found
        if [[ ! -e $1 ]]; then
            (exit 250)
        fi

        # file is not readable
        if [[ ! -r $1 ]]; then
            (exit 249)
        fi

        declare -la arr_output_thisFile=()

        while read str_line; do
            arr_output_thisFile+=("$str_line") || ( (exit 249) && arr_output_thisFile=() && break )
        done < $1

        # call functions
        SaveThisExitCode
        EchoPassOrFailThisExitCode
        ParseThisExitCode
    }

    function ReadInput
    {
        # behavior:
        #
        # ask for Yes/No answer, return boolean,
        # default selection is N/false
        # always returns bool
        #

        # parameters
        declare -ir int_maxCount=3
        declare -ar arr_count=$( seq $int_maxCount )

        for int_element in ${arr_count[@]}; do
            echo -en "$1 \e[30;43m[Y/n]:\e[0m "
            read str_input1
            str_input1=$( echo $str_input1 | tr '[:lower:]' '[:upper:]' )

            case $str_input1 in
                "Y"|"N")
                    break;;

                *)
                    if [[ $int_element -eq $int_maxCount ]]; then
                        str_input1="N"
                        echo -e "Exceeded max attempts. Default selection: \e[30;42m$str_input1\e[0m"
                        break
                    fi

                    echo -en "\e[33mInvalid input.\e[0m ";;
            esac
        done

        case $str_input1 in
            "Y")
                true;;

            "N")
                (exit 131);;
        esac

        # call functions
        SaveThisExitCode

        echo
    }

    function ReadInputFromMultipleChoiceIgnoreCase
    {
        # behavior:
        #
        # ask for multiple choice, up to eight choices
        # default selection is first choice
        # proper use always returns valid answer
        #

        if [[ -z $2 ]]; then
            (exit 254)

        else

            # parameters
            declare -ir int_maxCount=3
            declare -ar arr_count=$( seq $int_maxCount )

            for int_element in ${arr_count[@]}; do
                echo -en "$1 "
                read str_input1
                # str_input1=$( echo $str_input1 | tr '[:lower:]' '[:upper:]' )

                if [[ -z $2 && $str_input1 == $2 ]]; then
                    break

                elif [[ -z $3 && $str_input1 == $3 ]]; then
                    break

                elif [[ -z $4 && $str_input1 == $4 ]]; then
                    break

                elif [[ -z $5 && $str_input1 == $5 ]]; then
                    break

                elif [[ -z $6 && $str_input1 == $6 ]]; then
                    break

                elif [[ -z $7 && $str_input1 == $7 ]]; then
                    break

                elif [[ -z $8 && $str_input1 == $8 ]]; then
                    break

                elif [[ -z $9 && $str_input1 == $9 ]]; then
                    break

                else
                    if [[ $int_element -eq $int_maxCount ]]; then
                        str_input1=$2                       # default selection: first choice
                        echo -e "Exceeded max attempts. Default selection: \e[30;42m$str_input1\e[0m"
                        break
                    fi

                    echo -en "\e[33mInvalid input.\e[0m "
                    (exit 253)
                fi
            done
        fi

        # call functions
        SaveThisExitCode
        ParseThisExitCode
    }

    function ReadInputFromMultipleChoiceUpperCase
    {
        # behavior:
        #
        # ask for multiple choice, up to eight choices
        # default selection is first choice
        # proper use always returns valid answer
        #

        if [[ -z $2 ]]; then
            (exit 254)

        else

            # parameters
            declare -ir int_maxCount=3
            declare -ar arr_count=$( seq $int_maxCount )

            for int_element in ${arr_count[@]}; do
                echo -en "$1 "
                read str_input1
                str_input1=$( echo $str_input1 | tr '[:lower:]' '[:upper:]' )

                if [[ ! -z $2 && $str_input1 == $2 ]]; then
                    break

                elif [[ ! -z $3 && $str_input1 == $3 ]]; then
                    break

                elif [[ ! -z $4 && $str_input1 == $4 ]]; then
                    break

                elif [[ ! -z $5 && $str_input1 == $5 ]]; then
                    break

                elif [[ ! -z $6 && $str_input1 == $6 ]]; then
                    break

                elif [[ ! -z $7 && $str_input1 == $7 ]]; then
                    break

                elif [[ ! -z $8 && $str_input1 == $8 ]]; then
                    break

                elif [[ ! -z $9 && $str_input1 == $9 ]]; then
                    break

                else
                    if [[ $int_element -eq $int_maxCount ]]; then
                        str_input1=$2                       # default selection: first choice
                        echo -e "Exceeded max attempts. Default selection: \e[30;42m$str_input1\e[0m"
                        break
                    fi

                    echo -en "\e[33mInvalid input.\e[0m "
                    (exit 253)
                fi
            done
        fi

        # call functions
        SaveThisExitCode
        ParseThisExitCode
    }

    function ReadInputFromRangeOfNums
    {
        # behavior:
        #
        # ask for multiple choice, up to eight choices
        # default selection is first choice
        # proper use always returns valid answer
        #

        # parameters
        declare -ir int_maxCount=3
        declare -ar arr_count=$( seq $int_maxCount )

        for int_element in ${arr_count[@]}; do
            echo -en "$1 "
            read str_input1

            # valid input
            if [[ $str_input1 -ge $2 && $str_input1 -le $3 ]]; then
                break

            else

                # default input
                if [[ $int_element -eq $int_maxCount ]]; then
                    str_input1=$2                       # default selection: first choice
                    echo -e "Exceeded max attempts. Default selection: \e[30;42m$str_input1\e[0m"
                    break
                fi

                # check if string is a valid integer
                # if [[ ! ( "${str_input1}" -ge "$(( ${str_input1} ))" ) ]] 2> /dev/null; then
                #     echo -en "\e[33mInvalid input.\e[0m "
                # fi

                echo -en "\e[33mInvalid input.\e[0m "
            fi
        done
    }

    function SaveThisExitCode
    {
        int_thisExitCode=$?     # NOTE: this statement must follow an exit code statement, and come before any new statement
        # echo -e '\nDEBUG:\t$int_thisExitCode='"'$int_thisExitCode'"
    }

    function TestNetwork
    {
        # behavior:
        #   test internet connection and DNS servers
        #   return boolean, to be used by main
        #

        # test IP resolution
        echo -en "Testing Internet connection... "
        ( ping -q -c 1 8.8.8.8 &> /dev/null || ping -q -c 1 1.1.1.1 &> /dev/null ) || false

        # call functions
        SaveThisExitCode
        EchoPassOrFailThisExitCode

        echo -en "Testing connection to DNS... "
        ( ping -q -c 1 www.google.com &> /dev/null && ping -q -c 1 www.yandex.com &> /dev/null ) || false

        # call functions
        SaveThisExitCode
        EchoPassOrFailThisExitCode

        if [[ $int_thisExitCode -ne 0 ]]; then
            echo -e "Failed to ping Internet/DNS servers. Check network settings or firewall, and try again."
        fi

        echo
    }

    function WriteVarToFile
    {
        # behavior:
        #
        # input variable #2 ( $2 ) is the name of the variable we wish to point to
        # this may help with calling/parsing arrays
        # when passing the var, write the name without " $ "
        #

        # NOTE: necessary for newline preservation in arrays and files #
        SAVEIFS=$IFS   # Save current IFS (Internal Field Separator)
        IFS=$'\n'      # Change IFS to newline char

        echo -en "Writing to file... "

        # null exception
        if [[ -z $1 || -z $2 ]]; then
            (exit 254)
        fi

        # file not found exception
        if [[ ! -e $1 ]]; then
            (exit 253)
        fi

        # file not readable exception
        if [[ ! -r $1 ]]; then
            (exit 252)
        fi

        # file not readable exception
        if [[ ! -w $1 ]]; then
            (exit 251)
        fi

        if [[ $int_thisExitCode -eq 0 ]]; then
            echo $2 >> $1 || (exit 255)
        fi

        # call functions
        SaveThisExitCode
        EchoPassOrFailThisExitCode
        ParseThisExitCode
    }
##

## context functions ##
    function CheckIfIOMMU_IsEnabled
    {
        echo -en "Checking if Virtualization is enabled/supported... "

        # call functions
        if [[ ! -z $( compgen -G "/sys/kernel/iommu_groups/*/devices/*" ) ]]; then
            SaveThisExitCode
            EchoPassOrFailThisExitCode

        else
            SaveThisExitCode
            EchoPassOrFailThisExitCode
            ParseThisExitCode
            ExitWithThisExitCode
        fi
    }

    function CloneOrUpdateGitRepositories
    {
        echo -en "Cloning Git repositories... "

        # dir #
        # null exception
        if [[ -z $1 || -z $2 ]]; then
            (exit 254)
        fi

        # dir not found exception
        if [[ ! -d $1 ]]; then
            (exit 250)
        fi

        # dir not writeable exception
        if [[ ! -w $1 ]]; then
            (exit 248)
        fi

        if [[ $int_thisExitCode -eq 0 ]]; then
            cd $1

            # git repos #
            # null exception
            if [[ -z $1 || -z $2 ]]; then
                (exit 254)
            fi

            # dir not found exception
            if [[ ! -d $1 ]]; then
                (exit 250)
            fi

            # dir not writeable exception
            if [[ ! -w $1 ]]; then
                (exit 248)
            fi
        fi

        if [[ $int_thisExitCode -eq 0 ]]; then

            # if a given element is a string longer than one char, the var is an array #
            for str_element in ${2}; do
                if [[ ${#str_element} -gt 1 ]]; then
                    bool_varIsAnArray=true
                    break
                fi
            done

            declare -i int_count=1

            # git clone from array #
            if [[ $bool_varIsAnArray == true ]]; then
                for str_element in ${2}; do

                    # cd into repo, update, and back out
                    if [[ -e $( basename $1 ) ]]; then
                        cd $( basename $1 )
                        git pull $str_element &> /dev/null || ( ((int_count++)) && (exit 131) )
                        cd ..

                    # clone new repo
                    else
                        git clone $str_element &> /dev/null || ( ((int_count++)) && (exit 131) )
                    fi

                done

                # if all repos failed to clone, change exit code
                if [[ ${#2[@]} -eq $int_count ]]; then
                    (exit 255)
                fi

            # git clone a repo #
            else
                echo $2 >> $1 || (exit 255)
            fi
        fi

        # call functions
        SaveThisExitCode
        EchoPassOrFailThisExitCode
        ParseThisExitCode

        case $int_thisExitCode in
            131)
                echo -e "One or more Git repositories could not be cloned.";;
        esac

        echo
    }

    function ParseIOMMUandPCI
    {
        echo -en "Parsing IOMMU groups... "

        # parameters #
        declare -ir int_lastIOMMU="$( basename $( ls -1v /sys/kernel/iommu_groups/ | sort -hr | head -n1 ) )"
        declare -a arr_DeviceIOMMU=()
        declare -a arr_DevicePCI_ID=()
        declare -a arr_DeviceDriver=()
        declare -a arr_DeviceName=()
        declare -a arr_DeviceType=()
        declare -a arr_DeviceVendor=()
        bool_missingDriver=false
        bool_foundVFIO=false

        # parse list of IOMMU groups #
        for str_element1 in $( find /sys/kernel/iommu_groups/* -maxdepth 0 -type d | sort -V ); do

            # parameters #
            str_thisIOMMU=$( basename $str_element1 )

            # parse given IOMMU group for PCI IDs #
            for str_element2 in $( ls ${str_element1}/devices ); do

                # parameters #
                # save output of given device #
                str_thisDevicePCI_ID="${str_element2##"0000:"}"
                str_thisDeviceName="$( lspci -ms ${str_element2} | cut -d '"' -f6 )"
                str_thisDeviceType="$( lspci -ms ${str_element2} | cut -d '"' -f2 )"
                str_thisDeviceVendor="$( lspci -ms ${str_element2} | cut -d '"' -f4 )"
                str_thisDeviceDriver="$( lspci -ks ${str_element2} | grep driver | cut -d ':' -f2 )"

                if [[ -z $str_thisDeviceDriver ]]; then
                    str_thisDeviceDriver="N/A"
                    bool_missingDriver=true

                else
                    if [[ $str_thisDeviceDriver == *"vfio-pci"* ]]; then
                        str_thisDeviceDriver="N/A"
                        bool_foundVFIO=true

                    else
                        str_thisDeviceDriver="${str_thisDeviceDriver##" "}"
                    fi
                fi

                # parameters #
                arr_DeviceIOMMU+=( "$str_thisIOMMU" )
                arr_DevicePCI_ID+=( "$str_thisDevicePCI_ID" )
                arr_DeviceDriver+=( "$str_thisDeviceDriver" )
                arr_DeviceName+=( "$str_thisDeviceName" )
                arr_DeviceType+=( "$str_thisDeviceType" )
                arr_DeviceVendor+=( "$str_thisDeviceVendor" )
            done
        done

        readonly arr_DeviceIOMMU
        readonly arr_DevicePCI_ID
        readonly arr_DeviceDriver
        readonly arr_DeviceName
        readonly arr_DeviceType
        readonly arr_DeviceVendor

        # prioritize worst exit code (place last)
        case true in
            $bool_missingDriver)
                (exit 3);;

            $bool_foundVFIO)
                (exit 254);;
        esac

        # call functions
        SaveThisExitCode
        EchoPassOrFailThisExitCode

        case $int_thisExitCode in
                3)
                    echo -e "\e[33mWarning:\e[0m One or more external PCI device(s) missing drivers.";;

                254)
                    echo -e "Exception: No devices found.";;

                253)
                    echo -e "Exception: Existing VFIO setup found.";;
            esac

        echo
    }

    function SetupAutoXorg
    {
        # parameters #
        declare -r str_pwd=$( pwd )

        echo -e "Installing Auto-Xorg... "
        cd $( find -wholename Auto-Xorg | uniq | head -n1 ) && bash ./installer.bash && cd $str_pwd

        # call functions
        SaveThisExitCode
        EchoPassOrFailThisExitCode
        ParseThisExitCode

        echo
    }

    function SetupEvdev
    {
        # behavior:
        #
        # ask user to prep setup of Evdev
        # add active desktop users to groups for Libvirt, QEMU, Input devices, etc.
        # write to logfile
        #

        # parameters #
        declare -r str_thisFile1="qemu-evdev.log"
        declare -r str_thisFile2="/etc/apparmor.d/abstractions/libvirt-qemu"

        echo -e "Evdev (Event Devices) is a method of creating a virtual KVM (Keyboard-Video-Mouse) switch between host and VM's.\n\tHOW-TO: Press 'L-CTRL' and 'R-CTRL' simultaneously.\n"
        ReadInput "Setup Evdev?"

        if [[ $int_thisExitCode -eq 0 ]]; then
            # readonly str_firstUser=$( id -u 1000 -n ) && echo -e "Found the first desktop user of the system: $str_firstUser"

            # add users to groups #
            declare -a arr_User=($( getent passwd {1000..60000} | cut -d ":" -f 1 ))

            for str_element in $arr_User; do
                adduser $str_element input &> /dev/null       # quiet output
                adduser $str_element libvirt &> /dev/null     # quiet output
            done

            # output to file #
            CheckIfFileOrDirExists $str_thisFile1 &> /dev/null && DeleteFile $str_thisFile1 &> /dev/null
            ( CreateFile $str_thisFile1 ) || false

            if [[ $int_thisExitCode -eq 0 ]]; then

                # list of input devices #
                declare -ar arr_InputDeviceID=($( ls /dev/input/by-id ))
                declare -ar arr_InputEventDeviceID=($( ls -l /dev/input/by-id | cut -d '/' -f2 | grep -v 'total 0' ))
                declare -a arr_output_evdevQEMU=()

                # append output #
                for str_element in ${arr_InputDeviceID[@]}; do
                    arr_output_evdevQEMU+=("    \"/dev/input/by-id/$str_element\",")
                done

                for str_element in ${arr_InputEventDeviceID[@]}; do
                    arr_output_evdevQEMU+=("    \"/dev/input/by-id/$str_element\",")
                done

                readonly arr_output_evdevQEMU

                # append output #
                declare -ar arr_output_evdevApparmor=(
                    "  "
                    "  # Generated by 'portellam/deploy-VFIO-setup'"
                    "  #"
                    "  # WARNING: Any modifications to this file will be modified by 'deploy-VFIO-setup'"
                    "  #"
                    "  # Run 'systemctl restart apparmor.service' to update."
                    "  "
                    "  # Evdev #"
                    "  /dev/input/* rw,"
                    "  /dev/input/by-id/* rw,"
                )

                # debug #
                # echo -e '${#arr_InputDeviceID[@]}='"'${#arr_InputDeviceID[@]}'"
                # echo -e '${#arr_InputEventDeviceID[@]}='"'${#arr_InputEventDeviceID[@]}'"
                # echo -e '${#arr_output_evdevQEMU[@]}='"'${#arr_output_evdevQEMU[@]}'"

                # append file #
                CheckIfFileOrDirExists $str_thisFile1

                if [[ $int_thisExitCode -eq 0 ]]; then
                    for str_element in ${arr_output_evdevQEMU[@]}; do
                        WriteVarToFile $str_thisFile1 $str_element &> /dev/null || ( false && break )   # should this loop fail at any given time, exit
                    done
                fi

                # append system file #
                # will require restart of apparmor service or system
                if [[ $int_thisExitCode -eq 0 ]]; then
                    CheckIfFileOrDirExists $str_thisFile2 &> /dev/null

                    if [[ $int_thisExitCode -eq 0 ]]; then
                        for str_element in ${arr_output_evdevApparmor[@]}; do
                            WriteVarToFile $str_thisFile2 $str_element &> /dev/null || ( false && break )   # should this loop fail at any given time, exit
                        done

                        echo $arr_output_evdevQEMU &> /dev/null || false
                    fi
                fi
            fi
        fi

        # call functions
        SaveThisExitCode
        EchoPassOrFailThisExitCode "Setup Evdev..."
        ParseThisExitCode
    }

    function SetupHugepages
    {
        # behavior:
        #
        # find vars necessary for Hugepages setup
        # function can never *fail*, just execute or exit
        # write to logfile
        #

        # parameters #
        declare -r str_thisFile1="qemu-hugepages.log"
        declare -ir int_HostMemMaxK=$( cat /proc/meminfo | grep MemTotal | cut -d ":" -f 2 | cut -d "k" -f 1 )     # sum of system RAM in KiB
        str_GRUB_CMDLINE_Hugepages="default_hugepagesz=1G hugepagesz=1G hugepages=0"                                # default output

        echo -e "Hugepages is a feature which statically allocates system memory to pagefiles.\n\tVirtual machines can use Hugepages to a peformance benefit.\n\tThe greater the Hugepage size, the less fragmentation of memory, and the less latency/overhead of system memory-access.\n"
        ReadInput "Setup Hugepages?"

        if [[ $int_thisExitCode -eq 0 ]]; then

            # add users to groups #
            declare -ar arr_User=($( getent passwd {1000..60000} | cut -d ":" -f 1 ))

            for str_element in $arr_User; do
                adduser $str_element input &> /dev/null       # quiet output
                adduser $str_element libvirt &> /dev/null     # quiet output
            done

            # prompt #
            ReadInputFromMultipleChoiceUpperCase "Enter Hugepage size and byte-size \e[30;43m[1G/2M]:\e[0m" "1G" "2M"
            str_HugePageSize=$str_input1

            declare -ir int_HostMemMinK=4194304        # min host RAM in KiB

            # Hugepage Size #
            case $str_HugePageSize in
                "2M")
                    declare -ir int_HugePageK=2048     # Hugepage size
                    declare -ir int_HugePageMin=2;;    # min HugePages

                "1G")
                    declare -ir int_HugePageK=1048576  # Hugepage size
                    declare -ir int_HugePageMin=1;;    # min HugePages
            esac

            declare -ir int_HugePageMemMax=$(( $int_HostMemMaxK - $int_HostMemMinK ))
            declare -ir int_HugePageMax=$(( $int_HugePageMemMax / $int_HugePageK ))       # max HugePages

            # prompt #
            ReadInputFromRangeOfNums "Enter number of HugePages (n * $str_HugePageSize) \e[30;43m[$int_HugePageMin <= n <= $int_HugePageMax pages]:\e[0m" $int_HugePageMin $int_HugePageMax
            declare -ir int_HugePageNum=$str_input1

            # output #
            readonly str_output_hugepagesGRUB="default_hugepagesz=${str_HugePageSize} hugepagesz=${str_HugePageSize} hugepages=${int_HugePageNum}"
            readonly str_output_hugepagesQEMU="hugetlbfs_mount = \"/dev/hugepages\""

            # write to file #
            CheckIfFileOrDirExists $str_thisFile1 &> /dev/null && DeleteFile $str_thisFile1 &> /dev/null
            CreateFile $str_thisFile1 &> /dev/null

            if [[ $int_thisExitCode -eq 0 ]]; then
                WriteVarToFile $str_thisFile1 $str_output_hugepagesQEMU &> /dev/null && echo
            fi
        fi

        # call functions
        # SaveThisExitCode
        EchoPassOrFailThisExitCode "Setup Hugepages..."
        ParseThisExitCode
    }

    function SetupStaticCPU_isolation
    {
        function ParseCPU
        {
            # parameters #
            readonly arr_coresByThread=($(cat /proc/cpuinfo | grep 'core id' | cut -d ':' -f2 | cut -d ' ' -f2))
            readonly int_totalCores=$( cat /proc/cpuinfo | grep 'cpu cores' | uniq | grep -o '[0-9]\+' )
            readonly int_totalThreads=$( cat /proc/cpuinfo | grep 'siblings' | uniq | grep -o '[0-9]\+' )
            readonly int_SMT_multiplier=$(( $int_totalThreads / $int_totalCores ))
            # declare -a arr_totalCores=()
            declare -a arr_hostCores=()
            declare -a arr_hostThreads=()
            declare -a arr_hostThreadSets=()
            # declare -a arr_virtCores=()
            declare -a arr_virtThreadSets=()
            declare -i int_hostCores=1          # default value

            # reserve remainder cores to host #
            # >= 4-core CPU, leave max 2
            if [[ $int_totalCores -ge 4 ]]; then
                readonly int_hostCores=2

            # 2 or 3-core CPU, leave max 1
            elif [[ $int_totalCores -le 3 && $int_totalCores -ge 2 ]]; then
                readonly int_hostCores=1

            # 1-core CPU, do not reserve cores to virt
            else
                readonly int_hostCores=$int_totalCores
                (exit 255)
            fi

            # group threads for host #
            for (( int_i=0 ; int_i<$int_SMT_multiplier ; int_i++ )); do
                # declare -i int_firstHostCore=$int_hostCores
                declare -i int_firstHostThread=$((int_hostCores+int_totalCores*int_i))
                declare -i int_lastHostCore=$((int_totalCores-1))
                declare -i int_lastHostThread=$((int_lastHostCore+int_totalCores*int_i))

                if [[ $int_firstHostThread -eq $int_lastHostThread ]]; then
                    str_virtThreads+="${int_firstHostThread},"

                else
                    str_virtThreads+="${int_firstHostThread}-${int_lastHostThread},"
                fi
            done

            # update parameters #
            if [[ ${str_virtThreads: -1} == "," ]]; then
                str_virtThreads=${str_virtThreads::-1}
            fi

            # group threads by core id #
            for (( int_i=0 ; int_i<$int_totalCores ; int_i++ )); do
                str_line1=""
                declare -i int_thisCore=${arr_coresByThread[int_i]}

                for (( int_j=0 ; int_j<$int_SMT_multiplier ; int_j++ )); do
                    int_thisThread=$((int_thisCore+int_totalCores*int_j))
                    str_line1+="$int_thisThread,"

                    if [[ $int_thisCore -lt $int_hostCores ]]; then
                        arr_hostThreads+=("$int_thisThread")
                    fi
                done

                # update    str_output1="Setup 'Static' CPU isolation? [Y/n]: "

                arr_totalThreads+=("$str_line1")

                # save output for cpu isolation (host) #
                if [[ $int_thisCore -lt $int_hostCores ]]; then
                    arr_hostCores+=("$int_thisCore")
                    arr_hostThreadSets+=("$str_line1")

                # save output for cpuset/cpumask (qemu cpu pinning) #
                else
                    # arr_virtCores+=("$int_thisCore")
                    arr_virtThreadSets+=("$str_line1")
                fi
            done

            # update parameters #
            readonly arr_totalThreads
            readonly arr_hostCores
            readonly arr_hostThreadSets
            readonly arr_virtThreadSets

            # save output to string for cpuset and cpumask #
            #
            # example:
            #
            # host 0-1,8-9
            #
            # virt 2-7,10-15
            #
            #
            # cores     bit masks       mask
            # 0-7       0b11111111      FF      # total cores
            # 0,4       0b00010001      11      # host cores
            #
            # 0-11      0b111111111111  FFF     # total cores
            # 0-1,6-7   0b000011000011  C3      # host cores
            #
            # find cpu mask #
            readonly int_totalThreads_mask=$(( ( 2 ** $int_totalThreads ) - 1 ))
            declare -i int_hostThreads_mask=0

            for int_thisThread in ${arr_hostThreads[@]}; do
                int_hostThreads_mask+=$(( 2 ** $int_thisThread ))
            done

            # save output #
            if [[ $int_thisExitCode -eq 0 ]]; then
                readonly int_hostThreads_mask
                readonly hex_totalThreads_mask=$(printf '%x\n' $int_totalThreads_mask)  # int to hex #
                readonly hex_hostThreads_mask=$(printf '%x\n' $int_hostThreads_mask)    # int to hex #
                readonly str_GRUB_CMDLINE_CPU_Isolation="isolcpus=$str_virtThreads nohz_full=$str_virtThreads rcu_nocbs=$str_virtThreads"
            fi
        }

        # prompt #
        echo -e "CPU isolation (Static or Dynamic) is a feature which allocates system CPU threads to the host and Virtual machines (VMs), separately.\n\tVirtual machines can use CPU isolation or 'pinning' to a peformance benefit\n\t'Static' is more 'permanent' CPU isolation: installation will append to GRUB after VFIO setup.\n\tAlternatively, 'Dynamic' CPU isolation is flexible and on-demand: post-installation will execute as a libvirt hook script (per VM)."
        ReadInput "Setup 'Static' CPU isolation?" && echo -en "Executing CPU isolation setup... " && ParseCPU
        EchoPassOrFailThisExitCode
        ParseThisExitCode

        echo
    }

    function SetupZRAM_Swap
    {
        # parameters #
        declare -r str_pwd=$( pwd )

        # prompt #
        echo -e "Installing zram-swap... "

        if [[ $( systemctl status asshole &> /dev/null ) != *"could not be found"* ]]; then
            systemctl stop zramswap &> /dev/null
            systemctl disable zramswap &> /dev/null
        fi

        ( cd $( find -wholename zram-swap | uniq | head -n1 ) && sh ./install.sh && cd $str_pwd ) || (exit 255)

        # setup ZRAM #
        if [[ $int_thisExitCode -eq 0 ]]; then

            # disable all existing zram swap devices
            if [[ $( swapon -v | grep /dev/zram* ) == "/dev/zram"* ]]; then
                swapoff /dev/zram* &> /dev/null
            fi

            declare -ir int_hostMemMaxG=$(( int_HostMemMaxK / 1048576 ))
            declare -ir int_sysMemMaxG=$(( int_hostMemMaxG + 1 ))

            echo -e "Total system memory: <= ${int_sysMemMaxG}G.\nIf 'Z == ${int_sysMemMaxG}G - (V + X)', where ('Z' == ZRAM, 'V' == VM(s), and 'X' == remainder for Host machine).\n\tCalculate 'Z'."

            # free memory #
            if [[ ! -z $str_HugePageSize && ! -z $int_HugePageNum ]]; then
                case $str_HugePageSize in
                    "1G")
                        declare -ir int_hugePageSizeK=1048576;;

                    "2M")
                        declare -ir int_hugePageSizeK=2048;;
                esac

                declare -ir int_hugepagesMemG=$int_HugePageNum*$int_hugePageSizeK/1048576
                declare -ir int_hostMemFreeG=$int_sysMemMaxG-$int_hugepagesMemG
                echo -e "Free system memory after hugepages (${int_hugepagesMemG}G): <= ${int_hostMemFreeG}G."

            else
                declare -ir int_hostMemFreeG=$int_sysMemMaxG
                echo -e "Free system memory: <= ${int_hostMemFreeG}G."
            fi

            str_output1="Enter zram-swap size in G (0G < n < ${int_hostMemFreeG}G): "
            echo -en $str_output1
            read -r int_ZRAM_sizeG

            while true; do

                # attempt #
                if [[ $int_count -ge 2 ]]; then
                    ((int_ZRAM_sizeG=int_hostMemFreeG/2))      # default selection
                    echo -e "Exceeded max attempts. Default selection: ${int_ZRAM_sizeG}G"
                    break

                else
                    if [[ -z $int_ZRAM_sizeG || $int_ZRAM_sizeG -lt 0 || $int_ZRAM_sizeG -ge $int_hostMemFreeG ]]; then
                        echo -en "\e[33mInvalid input.\e[0m\n$str_output1"
                        read -r int_ZRAM_sizeG

                    else
                        break
                    fi
                fi

                ((int_count++))
            done

            declare -ir int_denominator="(( $int_sysMemMaxG / $int_ZRAM_sizeG ))"
            str_output1="\n_zram_fraction=\"1/$int_denominator\""
            # str_outFile1="/etc/default/zramswap"
            str_outFile1="/etc/default/zram-swap"

            CreateBackupFromFile $str_outFile1
            WriteVarToFile $str_outFile1 $str_output1 || (exit 255)
        fi

        # call functions
        SaveThisExitCode
        EchoPassOrFailThisExitCode "Zram-swap setup "
        ParseThisExitCode

        echo
    }
##

## executive functions
    function MultiBootSetup
    {
        echo -e "Executing Multi-boot setup..."
        # code here

        # parse IOMMU #
            shopt -s nullglob
            for str_line0 in $(find /sys/kernel/iommu_groups/* -maxdepth 0 -type d | sort -V); do

                # parameters #
                bool_driverIsValid=false
                bool_IOMMUcontainsExtPCI=false
                bool_IOMMUcontainsVGA=false
                declare -i int_thisIOMMU=$(echo $str_line0 | cut -d '/' -f5)
                str_input1=""
                echo -e "IOMMU Group: '$int_thisIOMMU'"

                for str_line1 in $str_line0/devices/*; do

                    # parameters #
                    str_line2=$(lspci -mns ${str_line1##*/})
                    str_thisBusID=$(echo $str_line2 | cut -d '"' -f1 | cut -d ' ' -f1)
                    str_thisHWID=$(lspci -n | grep $str_thisBusID | cut -d ' ' -f3)
                    str_thisDriver=$(lspci -kd $str_thisHWID | grep "driver" | cut -d ':' -f2 | cut -d ' ' -f2)
                    str_thisType=$(lspci -mmd $str_thisHWID | cut -d '"' -f2 | tr '[:lower:]' '[:upper:]')
                    str_line3=$(lspci -nnkd $str_thisHWID | grep -Eiv "DeviceName:|Kernel modules:|Subsystem:")

                    if [[ $str_thisDriver == *"vfio"* ]]; then
                        bool_foundExistingVFIOsetup=true
                    fi

                    if [[ -z $str_thisDriver || $str_thisDriver == "" ]]; then
                        str_thisDriver="N/A"
                        bool_driverIsValid=false

                    else
                        bool_driverIsValid=true
                    fi

                    # save all internal PCI drivers to list #
                    # parse this list to exclude these devices from blacklist
                    # example: 'snd_hda_intel' is used by on-board audio devices and VGA audio child devices
                    if [[ ${str_thisBusID::1} == "0" && ${str_thisBusID:1:1} -lt 1 ]]; then
                        str_internalPCI_driverList+="$str_thisDriver,"
                        str_internalPCI_HWIDList+="$str_thisHWID,"
                        bool_IOMMUcontainsExtPCI=false

                    else
                        bool_IOMMUcontainsExtPCI=true
                    fi

                    # save all IOMMU groups that contain VGA device(s) #
                    # parse this list for 'Multi-boot' function later on
                    if [[ $str_thisType == *"3D"* || $str_thisType == *"DISPLAY"* || $str_thisType == *"GRAPHIC"* || $str_thisType == *"VGA"* ]]; then
                        bool_IOMMUcontainsVGA=true
                    fi

                    # save drivers (of given device type) for 'pci-stub' (not 'vfio-pci') #
                    # parse this list for 'Multi-boot' function later on
                    # Why? Bind devices earlier than 'vfio-pci'
                    # GRUB:             parse this list and append to pci-stub
                    # system files:     parse this list and append to vfio-pci
                    if [[ $str_thisType == *"USB"* ]]; then                     # NOTE: update here!
                        str_PCISTUB_driverList+="$str_thisDriver,"
                    fi

                    # parse IOMMU if it cotains external PCI #
                    if [[ $bool_IOMMUcontainsExtPCI == true ]]; then
                        if [[ $bool_driverIsValid == false ]]; then
                            str_line3+="\n\tKernel driver in use: N/A"
                        fi

                        echo -e "\t$str_line3\n"

                    # save IGPU vendor and device name #
                    else
                        if [[ $bool_IOMMUcontainsVGA == true ]]; then
                            str_IGPUFullName=$(lspci -mmn | grep $str_thisBusID | cut -d '"' -f4)$(lspci -mmn | grep $str_thisBusID | cut -d '"' -f6)
                        fi
                    fi
                done;

                # prompt #
                str_output2=""

                if [[ $bool_IOMMUcontainsExtPCI == false ]]; then
                    str_output2="Skipped IOMMU group: External devices not found."
                else
                    str_output1="Select IOMMU group '$int_thisIOMMU'? [Y/n]: "
                    ReadInput $str_output1

                    if [[ $bool_IOMMUcontainsVGA == false ]]; then
                        case $str_input1 in
                            "Y")
                                arr_IOMMU_VFIO+=("$int_thisIOMMU")
                                str_output2="Selected IOMMU group.";;
                            "N")
                                arr_IOMMU_host+=("$int_thisIOMMU")
                                str_output2="Skipped IOMMU group.";;
                            *)
                                str_output2="Invalid input.";;
                        esac

                    else
                        case $str_input1 in
                            "Y")
                                arr_IOMMU_VFIOVGA+=("$int_thisIOMMU")
                                str_output2="Selected IOMMU group.";;
                            "N")
                                arr_IOMMU_hostVGA+=("$int_thisIOMMU")
                                str_output2="Skipped IOMMU group.";;
                            *)
                                str_output2="Invalid input.";;
                        esac
                    fi
                fi

                echo -e "\t$str_output2\n"
            done;

            if [[ ${#arr_IOMMU_VFIO[@]} -eq 0 && ${#arr_IOMMU_VFIOVGA[@]} -eq 0 ]]; then
                echo -e "Executing Multi-boot setup... Cancelled. No IOMMU groups selected."
                exit 1
            fi

        # parameters #
            bool_outputToGRUB=false
            readonly str_thisFile="${0##*/}"
            readonly str_logFile0="$str_thisFile.log"
            declare -a arr_VFIO_driver=()
            declare -a arr_VFIOVGA_driver=()
            str_thisFullName=""

            declare -a arr_GRUBmenuEntry=()
            declare -a arr_rootKernel+=($(ls -1 /boot/vmli* | cut -d "z" -f 2 | sort -r | head -n3))     # first three kernels
            readonly str_rootDisk=$(df / | grep -iv 'filesystem' | cut -d '/' -f3 | cut -d ' ' -f1)
            readonly str_rootDistro=$(lsb_release -i -s)                                                 # Linux distro name
            readonly str_rootUUID=$(blkid -s UUID | grep $str_rootDisk | cut -d '"' -f2)
            str_rootFSTYPE=$(blkid -s TYPE | grep $str_rootDisk | cut -d '"' -f2)

            if [[ $str_rootFSTYPE == "ext4" || $str_rootFSTYPE == "ext3" ]]; then
                readonly str_rootFSTYPE="ext2"
            fi

            # files #
            readonly str_dir1=$(find .. -name files)
            if [[ -e $str_dir1 ]]; then
                cd $str_dir1
            fi

            readonly str_inFile1=$(find . -name *etc_grub.d_proxifiedScripts_custom)
            readonly str_inFile1b=$(find . -name *Multi-boot_template)

            # comment to debug here #
            readonly str_outFile1="/etc/grub.d/proxifiedScripts/custom"

            # uncomment to debug here #
            readonly str_oldFile1="$str_outFile1.old"

            # create backup #
            if [[ -e $str_outFile1 ]]; then
                mv $str_outFile1 $str_oldFile1
            fi

            # restore backup #
            if [[ -e $str_inFile1 ]]; then
                cp $str_inFile1 $str_outFile1
            fi

            # create logfile #
            if [[ -e $str_logFile0 ]]; then
                rm $str_logFile0

            else
                touch $str_logFile0
            fi

        # parse VFIO IOMMU group(s) #
        for int_IOMMU_VFIO in ${arr_IOMMU_VFIO[@]}; do
            for str_line0 in $(find /sys/kernel/iommu_groups/$int_IOMMU_VFIO -maxdepth 0 -type d | sort -V); do
                for str_line1 in $str_line0/devices/*; do

                    # parameters #
                    str_line2=$(lspci -mns ${str_line1##*/})
                    str_thisBusID=$(echo $str_line2 | cut -d '"' -f1 | cut -d ' ' -f1)
                    str_thisHWID=$(lspci -n | grep $str_thisBusID | cut -d ' ' -f3)
                    str_thisDriver=$(lspci -kd $str_thisHWID | grep "driver" | cut -d ':' -f2 | cut -d ' ' -f2)

                    # add to lists #
                    if [[ $str_thisDriver != "" ]]; then
                        if [[ -z $(echo $str_internalPCI_driverList | grep $str_thisDriver) && -z $(echo $str_PCISTUB_driverList | grep $str_thisDriver) ]]; then
                            if [[ ${#str_VFIO_driverList[@]} != 0 && ! $(echo $str_VFIO_driverList | grep $str_thisDriver) ]]; then
                                arr_VFIO_driver+=("$str_thisDriver")
                                str_VFIO_driverList+="$str_thisDriver,"
                            fi

                            if [[ ${#str_VFIO_driverList[@]} == 0 ]]; then
                                arr_VFIO_driver+=("$str_thisDriver")
                                str_VFIO_driverList+="$str_thisDriver,"
                            fi
                        fi
                    fi

                    if [[ -z $(echo $str_internalPCI_HWIDList | grep $str_thisHWID) && -z $(echo $str_VFIO_HWIDList | grep $str_thisHWID) ]]; then
                        if [[ ${#str_PCISTUB_HWIDlist[@]} != 0 && -z $(echo $str_PCISTUB_HWIDlist | grep $str_thisHWID) ]]; then
                            if [[ ! -z $(echo $str_PCISTUB_driverList | grep $str_thisDriver) ]]; then
                                str_PCISTUB_HWIDlist+="$str_thisHWID,"

                            else
                                str_VFIO_HWIDList+="$str_thisHWID,"
                            fi
                        fi

                        if [[ ${#str_PCISTUB_HWIDlist[@]} == 0 ]]; then
                            if [[ ! -z $(echo $str_PCISTUB_driverList | grep $str_thisDriver) ]]; then
                                str_PCISTUB_HWIDlist+="$str_thisHWID,"

                            else
                                str_VFIO_HWIDList+="$str_thisHWID,"
                            fi
                        fi
                    fi
                done
            done
        done

        # parse VFIO IOMMU group(s) with VGA device(s) #
        for int_IOMMU_VFIOVGA in ${arr_IOMMU_VFIOVGA[@]}; do

            # update parameters #
            str_PCISTUBVGA_HWIDlist=""
            str_VFIOVGA_driverList=""
            str_VFIOVGA_HWIDList=""

            for str_line0 in $(find /sys/kernel/iommu_groups/* -maxdepth 0 -type d | sort -V); do

                # parameters #
                declare -i int_thisIOMMU=$(echo $str_line0 | cut -d '/' -f5)

                for str_line1 in $str_line0/devices/*; do

                    # parameters #
                    str_line2=$(lspci -mns ${str_line1##*/})
                    str_thisBusID=$(echo $str_line2 | cut -d '"' -f1 | cut -d ' ' -f1)
                    str_thisHWID=$(lspci -n | grep $str_thisBusID | cut -d ' ' -f3)
                    str_thisDriver=$(lspci -kd $str_thisHWID | grep "driver" | cut -d ':' -f2 | cut -d ' ' -f2)
                    str_thisType=$(lspci -mmd $str_thisHWID | cut -d '"' -f2 | tr '[:lower:]' '[:upper:]')

                    # add to lists #
                    if [[ $int_thisIOMMU != $int_IOMMU_VFIOVGA ]]; then
                        if [[ $str_thisDriver != "" ]]; then
                            if [[ -z $(echo $str_internalPCI_driverList | grep $str_thisDriver) && -z $(echo $str_PCISTUB_driverList | grep $str_thisDriver) && -z $(echo $str_VFIO_driverList | grep $str_thisDriver) && -z $(echo $str_VFIOVGA_driverList | grep $str_thisDriver) ]]; then
                                arr_VFIOVGA_driver+=("$str_thisDriver")
                                str_VFIOVGA_driverList+="$str_thisDriver,"
                            fi
                        fi

                        if [[ -z $(echo $str_internalPCI_HWIDList | grep $str_thisHWID) && -z $(echo $str_PCISTUB_HWIDlist | grep $str_thisHWID) && -z $(echo $str_VFIO_HWIDList | grep $str_thisHWID) ]]; then
                            if [[ ! -z $(echo $str_PCISTUB_driverList | grep $str_thisDriver) ]]; then
                                str_PCISTUBVGA_HWIDlist+="$str_thisHWID,"

                            else
                                str_VFIOVGA_HWIDList+="$str_thisHWID,"
                            fi
                        fi

                    # save VGA vendor and device name #
                    else
                        if [[ $str_thisType == *"3D"* || $str_thisType == *"DISPLAY"* || $str_thisType == *"GRAPHIC"* || $str_thisType == *"VGA"* ]]; then
                            str_thisFullName=$(lspci -mnn | grep $str_thisBusID | cut -d '"' -f4)" ")lspci -mnn | grep $str_thisBusID | cut -d '"' -f6)
                        fi
                    fi
                done
            done

            # update parameters #
            str_thisPCISTUB_HWIDList=${str_PCISTUB_HWIDlist}${str_PCISTUBVGA_HWIDlist}
            str_thisVFIO_driverList=${str_VFIO_driverList}${str_VFIOVGA_driverList}
            str_thisVFIO_HWIDList=${str_VFIO_HWIDList}${str_VFIOVGA_HWIDList}

            # remove last separator #
            if [[ ${str_thisPCISTUB_HWIDList: -1} == "," ]]; then
                str_thisPCISTUB_HWIDList=${str_thisPCISTUB_HWIDList::-1}
            fi

            if [[ ${str_thisVFIO_driverList: -1} == "," ]]; then
                str_thisVFIO_driverList=${str_thisVFIO_driverList::-1}
            fi

            if [[ ${str_thisVFIO_HWIDList: -1} == "," ]]; then
                str_thisVFIO_HWIDList=${str_thisVFIO_HWIDList::-1}
            fi

            # write to file #

                # parameters #
                if [[ $str_IGPUFullName != "N/A" && $str_IGPUFullName != "" ]]; then
                    str_thisFullName=$str_IGPUFullName
                fi

                # NOTE: update here!
                str_GRUB_CMDLINE="${str_GRUB_CMDLINE_prefix} modprobe.blacklist=${str_thisVFIO_driverList} pci-stub.ids=${str_thisPCISTUB_HWIDList} vfio_pci.ids=${str_thisVFIO_HWIDList}"

                # log file #
                echo -e "#${int_IOMMU_VFIOVGA} #${str_thisFullName} #${str_GRUB_CMDLINE}" >> $str_logFile0

                ## /etc/grub.d/proxifiedScripts/custom ##

                    # parse kernels #
                    for (( int_i=0 ; int_i<${#arr_rootKernel[@]} ; int_i++)); do

                        # match #
                        if [[ -e ${arr_rootKernel[$int_i]} || ${arr_rootKernel[$int_i]} != "" ]]; then
                            str_thisRootKernel=${arr_rootKernel[$int_i]:1}

                            # parameters #
                            str_thisGRUBmenuEntry=$(lsb_release -i -s)" "$(uname -o)", with "$(uname)" $str_thisRootKernel (VFIO, w/o IOMMU '$int_IOMMU_VFIO_VGA', w/ boot VGA '$str_thisFullName')"
                            arr_GRUBmenuEntry+=("$str_thisGRUBmenuEntry")
                            str_output1="menuentry \"$str_thisGRUBmenuEntry\" {"
                            str_output1_log="\n"'menuentry "'$(lsb_release -i -s)" "$(uname -o)", with "$(uname)" #kernel_'$int_i'# (VFIO, w/o IOMMU '$int_IOMMU_VFIOVGA', w/ boot VGA '$str_thisFullName'\") {"
                            str_output2="\tinsmod $str_rootFSTYPE"
                            str_output3="\tset root='/dev/disk/by-uuid/$str_rootUUID'"
                            str_output4="\t"'if [ x$feature_platform_search_hint = xy ]; then'"\n\t\t"'search --no-floppy --fs-uuid --set=root '"$str_rootUUID\n\t"'fi'
                            str_output5="\techo    'Loading Linux $str_thisRootKernel ...'"
                            str_output5_log="\techo    'Loading Linux #kernel'$int_i'# ...'"
                            str_output6="\tlinux   /boot/vmlinuz-$str_thisRootKernel root=UUID=$str_rootUUID $str_GRUB_CMDLINE"
                            str_output6_log="\tlinux   /boot/vmlinuz-#kernel'$int_i'# root=UUID=$str_rootUUID $str_GRUB_CMDLINE"
                            str_output7="\tinitrd  /boot/initrd.img-$str_thisRootKernel"
                            str_output7_log="\tinitrd  /boot/initrd.img-"'#kernel'$int_i'#'

                            # debug prompt #
                            # echo -e "'$""str_output0'\t\t= $str_output0"
                            # echo -e "'$""str_output1'\t\t= $str_output1"
                            # echo -e "'$""str_output2'\t\t= $str_output2"
                            # echo -e "'$""str_output3'\t\t= $str_output3"
                            # echo -e "'$""str_output4'\t\t= $str_output4"
                            # echo -e "'$""str_output5'\t\t= $str_output5"
                            # echo -e "'$""str_output6'\t\t= $str_output6"
                            # echo -e "'$""str_output7'\t\t= $str_output7"
                            # echo

                            if [[ -e $str_inFile1 && -e $str_inFile1b ]]; then

                                # write to tempfile #
                                echo -e >> $str_outFile1

                                while read -r str_line1; do
                                    case $str_line1 in

                                        *'#$str_output1'*)
                                            str_outLine1="$str_output1";;

                                        *'#$str_output2'*)
                                            str_outLine1="$str_output2";;

                                        *'#$str_output3'*)
                                            str_outLine1="$str_output3";;

                                        *'#$str_output4'*)
                                            str_outLine1="$str_output4";;

                                        *'#$str_output5'*)
                                            str_outLine1="$str_output5";;

                                        *'#$str_output6'*)
                                            str_outLine1="$str_output6";;

                                        *'#$str_output7'*)
                                            str_outLine1="$str_output7";;

                                        *)
                                            str_outLine1="$str_line1";;
                                    esac

                                    # write to system file and logfile (post_install: update Multi-boot) #
                                    echo -e "$str_outLine1" >> $str_outFile1
                                done < $str_inFile1b        # read from template
                            else
                                bool_missingFiles=true
                            fi
                        fi
                    done

        # file check #
            if [[ $bool_missingFiles == true ]]; then
                echo -e "File(s) missing:"

                if [[ -z $str_inFile1 ]]; then
                    echo -e "\t'$str_inFile1'"
                fi

                if [[ -z $str_inFile1b ]]; then
                    echo -e "\t'$str_inFile1b'"
                fi

                echo -e "Executing Multi-boot setup... Failed."
                exit 1

            else
                chmod 755 $str_outFile1 $str_oldFile1                   # set proper permissions
                echo -e "Executing Multi-boot setup... Complete."
            fi
        done

        ParseThisExitCode "Executing Multi-boot setup..."
    }

    function ParseInputParamForOptions
    {
        declare -lar arr_options=(
            "--help"
            "-h"
            "--full"
            "-f"
            "--multiboot"
            "-m"
            "--static"
            "-s"
            "--uninstall"
            "-u"
        )

        str_helpPrompt="Usage: $0 [ OPTIONS ]
            \nwhere OPTIONS
            \n\t-h --help\tDisplay this prompt.
            \n\t-f --full\tExecute pre-setup and post-setup, and prompt for either VFIO setup.
            \n\t-m --multiboot\tExecute Multiboot VFIO setup only.
            \n\t-s --static\tExecute Static VFIO setup only.
            \n\t-u --uninstall\tUninstall existing VFIO setup."

        if [[ ! -z $1 ]]; then
            str_option=$( echo $1 | tr '[:upper:]' '[:lower:]' )

            case $str_option in
                "--"*|"-"*)
                    for str_element in ${arr_options[@]}; do
                        for int_key in ${!arr_options[@]}; do
                            if [[ ${arr_options[$int_key]} == $str_element && $str_element == $str_option ]]; then
                                declare -lir int_thisKey=$int_key
                                (exit 0)
                                SaveThisExitCode
                                break
                            fi
                        done
                    done

                    if [[ -z $int_thisKey ]]; then
                        (exit 253)
                        SaveThisExitCode
                    fi
                    ;;

                *)
                    (exit 253)
                    SaveThisExitCode
                    ;;
            esac
        fi

        case $int_thisKey in
            0|1)
                bool_execHelp=true;;

            2|3)
                bool_execFullSetup=true;;

            4|5)
                bool_execMultiBootSetup=true;;

            6|7)
                bool_execStaticSetup=true;;

            8|9)
                bool_execUninstallSetup=true;;
        esac

        if [[ $int_thisExitCode -ne 0 ]]; then
            ParseThisExitCode
            echo -e $str_helpPrompt
            ExitWithThisExitCode
        fi

        if [[ $bool_execHelp == true ]]; then
            echo -e $str_helpPrompt
            ParseThisExitCode
            ExitWithThisExitCode
        fi

        ParseThisExitCode
    }

    function PreInstallSetup
    {
        echo -e "Executing Pre-install setup..."

        # parameters
        declare -r str_file1="etc_libvirt_qemu.conf"
        # declare -r str_file2="/etc/libvirt/qemu.conf"
        declare -r str_file2="test-qemu.conf"            # debug

        CreateFile $str_file2                             # debug

        # restore system file from repo backup if local backups do not exist #
        # if ( CheckIfFileOrDirExists $str_file1 == true && CheckIfFileOrDirExists $str_file2 == false); then
        #     cp $str_file1 $str_file2
        # fi

        # append to system file
        declare -a arr_output1=(
            "# Generated by 'portellam/deploy-VFIO-setup'"
            "#"
            "# WARNING: Any modifications to this file will be modified by 'deploy-VFIO-setup'"
            "#"
            "# Run 'systemctl restart libvirtd.service' to update."
            " "
            "# User permissions #"
            "#     user = \"user\""
            "#     group = \"user\""
            "#"
        )

        # find first desktop user, add user to groups for libvirt/qemu, hugepages, and evdev
        readonly str_firstUser=$( id -u 1000 -n ) && (
            adduser $str_firstUser libvirt &> /dev/null
            adduser $str_firstUser input &> /dev/null
            )

        SaveThisExitCode

        # append to system file
        if [[ $int_thisExitCode -eq 0 ]]; then
            arr_output1+=(
                "user = \"${str_firstUser}\""
                "group = \"user\""
                "#"
            )
        fi

        # execute Hugepages setup
        bool_isHugepagesSetup=false
        SetupHugepages && bool_isHugepagesSetup=true

        # echo -e "str_GRUB_CMDLINE_Hugepages:'${str_GRUB_CMDLINE_Hugepages}'"  # this scope does work!

        # append
        if [[ $bool_isHugepagesSetup == true ]]; then
            #arr_output1+=("${str_output_hugepagesQEMU}")

            while read str_line; do
                arr_output1+=("$str_line")
                echo $str_line
            done < "qemu-hugepages.log"

            arr_output1+=("#")
        fi

        # append
        arr_output1+=(
            "cgroup_device_acl = ["
        )

        # execute Evdev setup
        bool_isEvdevSetup=false
        SetupEvdev && bool_isEvdevSetup=true

        # append
        if [[ $bool_isEvdevSetup == true ]]; then
            # echo -e '${#arr_output_evdevQEMU[@]}='"'${#arr_output_evdevQEMU[@]}'"

            # for str_element in ${arr_output_evdevQEMU[@]}; do
            #     arr_output1+=("${str_element}")
            # done

            # arr_output1+=($( cat $str_thisFile1 ))

            # echo $str_thisFile1

            # ReadFile "qemu-evdev.log"

            # for str_element in ${arr_output_thisFile[@]}; do
            #     arr_output1+=("${str_element}")
            #     echo $str_element
            # done

            while read str_line; do
                arr_output1+=("$str_line")
                echo $str_line
            done < "qemu-evdev.log"
        fi

        # append #
        arr_output1+=(
            "    \"/dev/null\", \"/dev/full\", \"/dev/zero\","
            "    \"/dev/random\", \"/dev/urandom\","
            "    \"/dev/ptmx\", \"/dev/kvm\","
            "    \"/dev/rtc\",\"/dev/hpet\""
            "]"
            "#"
        )

        if ( CreateBackupFromFile $str_file2 &> /dev/null == true ); then
            for str_element in ${arr_output1[@]}; do
                if [[ $int_thisExitCode -ne 0 ]]; then
                    break
                fi

                ( WriteVarToFile $str_file2 $str_element &> /dev/null && true ) || ( bool_fail_outputIsQuiet && false )
            done

        else
            echo -e "\e[33mWARNING:\e[0m"" Setup cannot continue." && ExitWithThisExitCode
        fi

        SetupStaticCPU_isolation && bool_isCPU_staticIsolationSetup=true

        # TO-DO: add check for necessary dependencies or packages

        if [[ TestNetwork == true ]]; then

            # zram-swap
            if ( CloneOrUpdateGitRepositories "FoundObjects/zram-swap" ); then
                SetupZRAM_Swap && bool_isZRAM_swapSetup=true
            fi

            # auto-xorg
            if ( CloneOrUpdateGitRepositories "portellam/auto-xorg" ); then
                SetupAutoXorg && bool_isAutoXorgSetup=true
            fi

        else

            # zram-swap
            if ( CheckIfFileOrDirExists "zram-swap" == true ); then
                SetupZRAM_Swap && bool_isZRAM_swapSetup=true
            fi

            # auto-xorg
            if ( CheckIfFileOrDirExists "auto-xorg" ); then
                SetupAutoXorg && bool_isAutoXorgSetup=true
            fi
        fi

        if [[ $bool_isAutoXorgSetup == false && $bool_isCPU_staticIsolationSetup == false && $bool_isHugepagesSetup == false && $bool_isZRAM_swapSetup == false ]]; then
            echo -e "\e[33mWARNING:\e[0m"" Failed pre-setup."
        fi

        ParseThisExitCode "Executing Pre-install setup..."
    }

    function PostInstallSetup
    {
        echo -e "Executing Post-install setup..."
        # code here

        ParseThisExitCode "Executing Post-install setup..."
    }

    function StaticSetup
    {
        echo -e "Executing Static setup..."
        ParseIOMMUandPCI
        # code here

        ParseThisExitCode "Executing Static setup..."
    }

    function UninstallSetup
    {
        echo -en "Executing Uninstaller..."
        # code here
        ParseThisExitCode
    }
##

## execution
    # NOTE: necessary for newline preservation in arrays and files
    SAVEIFS=$IFS   # Save current IFS (Internal Field Separator)
    IFS=$'\n'      # Change IFS to newline char

    # checks
    CheckIfUserIsRoot
    CheckIfIOMMU_IsEnabled

    if [[ -z $2 ]]; then
        ParseInputParamForOptions $1

        if [[ $bool_execUninstallSetup == true ]]; then
            UninstallSetup

        else
            if [[ $bool_execFullSetup == true ]]; then
                PreInstallSetup
            fi

            case true in
                $bool_execMultiBootSetup)
                    MultiBootSetup;;

                $bool_execStaticSetup)
                    StaticSetup;;

                *)
                    ReadInputFromMultipleChoiceUpperCase "Execute Multiboot or Static setup? [M/S]:" "M" "S"

                    case $str_input1 in
                        "M")
                            MultiBootSetup;;

                        "S")
                            StaticSetup;;
                    esac
                    ;;
            esac

            if [[ $bool_execFullSetup == true ]]; then
                PostInstallSetup
            fi
        fi

    else
        (exit 254)
        SaveThisExitCode
        ParseThisExitCode "Cannot parse multiple options."
    fi

    ExitWithThisExitCode
##