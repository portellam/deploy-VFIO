#!/bin/bash sh

#
# Filename:         deploy-vfio-setup.bash
# Description:      The Ultimate script to seamlessly deploy a VFIO setup (PCI passthrough).
# Author(s):        Alex Portell <github.com/portellam>
# Maintainer(s):    Alex Portell <github.com/portellam>
#

#
# TODO
#
# - bash libraries, add input param to disable checks? to reduce recursive steps?
#
#
# -append changes for sysctl.conf (shared memory, evdev, LookingGlass, Scream, etc.) to individual files?
#
# -Continuous Improvement: after conclusion of this script's dev. Propose a refactor using the bashful libraries and with better Bash principles in mind.
# -demo the product: get a working, debuggable version ASAP.
# -revise README, files
# -pull down original system files from somewhere
# -or provide checksum of my backups of system files
#
#

# <remarks> deploy-vfio-setup </remarks>
    # <summary> Business functions: Validation </summary>
    # <code>
        function DetectExisting_VFIO
        {
            return 0
        }

        function IsEnabled_IOMMU
        {
            # <params>
            local readonly str_output="Checking if Virtualization is enabled/supported..."
            local readonly var_command='compgen -G "/sys/kernel/iommu_groups/*/devices/*"'
            # </params>

            if eval "${var_command}";
                echo -e "${str_suffix_pass}"
            then
                echo -e "${str_suffix_fail}"
                return 1
            fi

            return 0
        }
    # </code>

    # <summary> Business functions: Get IOMMU </summary>
    # <code>
        # <summary> Parse IOMMU groups for all relevant information. If a parse fails, attempt again another way. If all parses fail, return error </summary>
        function Parse_IOMMU
        {
            function Parse_IOMMU_Main
            {
                function Parse_IOMMU_Are_Inequal_Lists_Sizes
                {
                    local bool_are_inequal_lists=false
                    [ "${#arr_IOMMU[@]}" -eq "${#arr_class[@]}" ] || bool_are_inequal_lists=true
                    # [ "${#arr_IOMMU[@]}" -eq "${#arr_device_ID[@]}" ] || bool_are_inequal_lists=true
                    [ "${#arr_IOMMU[@]}" -eq "${#arr_device_name[@]}" ] || bool_are_inequal_lists=true
                    [ "${#arr_IOMMU[@]}" -eq "${#arr_driver[@]}" ] || bool_are_inequal_lists=true
                    [ "${#arr_IOMMU[@]}" -eq "${#arr_hardware_ID[@]}" ] || bool_are_inequal_lists=true
                    # [ "${#arr_IOMMU[@]}" -eq "${#arr_vendor_ID[@]}" ] || bool_are_inequal_lists=true
                    [ "${#arr_IOMMU[@]}" -eq "${#arr_vendor_name[@]}" ] || bool_are_inequal_lists=true

                    if "${bool_are_inequal_lists}"; then
                        echo -e "${str_output_lists_inequal}"
                        return 1
                    fi

                    return 0
                }

                function Parse_IOMMU_Are_Not_Empty_Lists
                {
                    # <remarks> If any list is empty, fail. </remarks>
                    local bool_is_empty_list=false
                    CheckIfVarIsVar "${arr_class[@]}" &> /dev/null || bool_is_empty_list=true
                    # CheckIfVarIsVar "${arr_device_ID[@]}" &> /dev/null || bool_is_empty_list=true
                    CheckIfVarIsVar "${arr_device_name[@]}" &> /dev/null ||  bool_is_empty_list=true
                    CheckIfVarIsVar "${arr_driver[@]}" &> /dev/null || bool_is_empty_list=true
                    CheckIfVarIsVar "${arr_hardware_ID[@]}" &> /dev/null || bool_is_empty_list=true
                    CheckIfVarIsVar "${arr_IOMMU[@]}" &> /dev/null || bool_is_empty_list=true
                    # CheckIfVarIsVar "${arr_vendor_ID[@]}" &> /dev/null || bool_is_empty_list=true
                    CheckIfVarIsVar "${arr_vendor_name[@]}" &> /dev/null || bool_is_empty_list=true

                    if "${bool_is_empty_list}"; then
                        echo -e "${str_output_list_empty}"
                        return 1
                    fi

                    return 0
                }

                function Parse_IOMMU_Save_Lists
                {
                    # <remarks> Save to lists each device's information. Lists should be of the same-size. </remarks>
                    for str_slot_ID in "${arr_devices[@]}"; do
                        local str_class=$( eval "${var_parse_name_ID}" )
                        str_class=$( echo -e "${str_class}" | grep -i "Class:" | cut -d ':' -f 2 | grep -oP "^\t\K.*" )
                        # local str_device_ID=$( eval "${var_parse_all_ID}" | grep -i "Device:" | grep -Eiv "SDevice:|${str_slot_ID}" | awk '{print $2}' | uniq )
                        local str_device_ID=$( eval "${var_parse_quotes}" | cut -d '"' -f 6 | uniq )
                        local str_device_name=$( eval "${var_parse_name_ID}" | grep -i "Device:" | grep -Eiv "SDevice:|${str_slot_ID}" | cut -d ':' -f 2 | uniq | grep -oP "^\t\K.*" )
                        local str_driver=$( eval "${var_parse_all_ID}" | grep -i "Driver:" | awk '{print $2}' | uniq )
                        local str_IOMMU=$( eval "${var_parse_all_ID}"| grep -i "IOMMUGroup:" | awk '{print $2}' | uniq )
                        local str_vendor_name=$( eval "${var_parse_name_ID}" | grep -i "Vendor:" | grep -Eiv "SVendor:" | cut -d ':' -f 2 | uniq | grep -oP "^\t\K.*" )
                        # local str_vendor_ID=$( eval "${var_parse_all_ID}" | grep -i "Vendor:" | awk '{print $2}' | uniq )
                        local str_vendor_ID=$( eval "${var_parse_quotes}" | cut -d '"' -f 4 | uniq )

                        # <remarks> If system is setup for VFIO, exit. </remarks>
                        if [[ "${str_driver}" == "vfio-pci" ]]; then
                            echo -e "${str_output_is_setup_VFIO}"
                            return 1
                        fi

                        # <remarks> Match invalid input, and save as known null value. </remarks>
                        if ! CheckIfVarIsVar "${str_driver}" &> /dev/null; then
                            local str_driver="N/A"
                        fi

                        arr_class+=( "${str_class}" )
                        # arr_device_ID+=( "${str_device_ID}" )
                        arr_device_name+=( "${str_device_name}" )
                        arr_driver+=( "${str_driver}" )
                        arr_IOMMU+=( "${str_IOMMU}" )
                        arr_slot_ID+=( "${str_slot_ID}" )
                        # arr_vendor_ID+=( "${str_vendor_ID}" )
                        arr_vendor_name+=( "${str_vendor_name}" )
                        arr_hardware_ID+=( "${str_vendor_ID}:${str_device_ID}" )
                    done

                    return 0
                }

                function Parse_IOMMU_Set_Operation
                {
                    # <remarks> Set commands for each parse type. </remarks>
                    case "${var_opt}" in

                        # <remarks> If parsing file and file does not exist, recursive call to parse internet. </remarks>
                        "${str_opt_parse_file}" )
                            str_output="${str_output_parse_file}"
                            echo -e "${str_output}"

                            var_parse_all_ID+="${var_parse_args_file}"
                            var_parse_name_ID+="${var_parse_args_file}"
                            var_parse_slot_ID+="${var_parse_args_file}"
                            var_parse_quotes+="${var_parse_args_file}"

                            CheckIfFileExists "${str_file}" &> /dev/null
                            return "${?}"
                            ;;

                        # <remarks> If internet is not available, exit. </remarks>
                        "${str_opt_parse_internet}" )
                            str_output="${str_output_parse_internet}"
                            echo -e "${str_output}"

                            local readonly var_parse_all_ID+="${var_parse_args_online}"
                            local readonly var_parse_name_ID+="${var_parse_args_online}"
                            local readonly var_parse_slot_ID+="${var_parse_args_online}"
                            local readonly var_parse_quotes+="${var_parse_args_online}"

                            GetInternetStatus
                            return "${?}"
                            ;;

                        "${str_opt_parse_local}" | * )
                            str_output="${str_output_parse_local}"
                            echo -e "${str_output}"
                            ;;
                    esac

                    return 0
                }

                # <params>
                    # <remarks> Save input params </remarks>
                    var_opt="${1}"

                    # <remarks> Output statements </remarks>
                    local readonly str_output_lists_inequal="${var_prefix_error} System PCI lists' sizes are inequal."
                    local readonly str_output_list_empty="${var_prefix_error} One or more system PCI lists are empty."
                    local readonly str_output_parse_file="Parsing PCI from file..."
                    local readonly str_output_parse_internet="Parsing PCI devices from Internet database..."
                    local readonly str_output_parse_local="Parsing PCI devices from local database..."
                    local readonly str_output_is_setup_VFIO="${var_prefix_error} Found existing VFIO setup."

                    # <remarks> Declare lists </remarks>
                    declare -ag arr_class arr_device_ID arr_device_name arr_driver arr_hardware_ID arr_IOMMU arr_slot_ID arr_vendor_ID arr_vendor_name

                    # <remarks> Set commands </remarks>
                    local readonly var_parse='lspci -k -mm'
                    local readonly var_parse_args_file='-F "${str_file}"'
                    local readonly var_parse_args_online='-q'
                    local readonly var_parse_args_nums='-n'
                    local readonly var_parse_args_slot_ID='-s ${str_slot_ID}'
                    local readonly var_parse_args_verbose='-v'
                    local readonly var_parse_to_file='lspci -x >> "${str_file}"'

                    local var_parse_all_ID="${var_parse} ${var_parse_args_nums} ${var_parse_args_verbose} ${var_parse_args_slot_ID}"
                    local var_parse_name_ID="${var_parse} ${var_parse_args_verbose} ${var_parse_args_slot_ID}"
                    local var_parse_slot_ID="${var_parse}"
                    local var_parse_quotes="${var_parse} ${var_parse_args_nums}"
                # </params>

                # <remarks> Set commands for each parse type. </remarks>
                Parse_IOMMU_Set_Operation || return "${?}"

                # <remarks> Get all devices from system. </remarks>
                declare -a arr_devices=( $( eval ${var_parse_slot_ID} | awk '{print $1}' ) )
                Parse_IOMMU_Save_Lists || return "${?}"

                Parse_IOMMU_Are_Not_Empty_Lists || return "${?}"
                Parse_IOMMU_Are_Inequal_Lists_Sizes || return "${?}"

                # <remarks> Save output to file. </remarks>
                if [[ "${?}" -eq 0 && "${var_opt}" != "${str_opt_parse_file}" ]]; then
                    CheckIfFileExists "${str_file}" &> /dev/null && eval "${var_parse_to_file}"
                fi

                return 0
            }

            # <params>
                # <remarks> Set parse options </remarks>
                local readonly str_opt_parse_file="FILE"
                local readonly str_opt_parse_internet="DNS"
                local readonly str_opt_parse_local="LOCAL"

                # <remarks> Save input params </remarks>
                local var_opt="${1}"
                local readonly str_file="${2}"
            # </params>

            # <remarks> If an operation fails, try another. </remarks>
            case "${var_opt}" in
                "${str_opt_parse_internet}" )
                    Parse_IOMMU_Main "${str_opt_parse_internet}" "${str_file}"
                    ;;

                "${str_opt_parse_file}" )
                    Parse_IOMMU_Main "${str_opt_parse_file}" "${str_file}" || Parse_IOMMU_Main "${str_opt_parse_internet}" "${str_file}"
                    ;;

                "${str_opt_parse_local}" | * )
                    Parse_IOMMU_Main "${str_opt_parse_local}" "${str_file}" || Parse_IOMMU_Main "${str_opt_parse_file}" "${str_file}" || Parse_IOMMU_Main "${str_opt_parse_internet}" "${str_file}"
                    ;;
            esac

            AppendPassOrFail "${str_output}"

            # <remarks> Save output. </remarks>
            readonly arr_class arr_device_ID arr_device_name arr_driver arr_hardware_ID arr_IOMMU arr_slot_ID arr_vendor_ID arr_vendor_name

            return "${int_exit_code}"
        }

        function Select_IOMMU
        {
            function Select_IOMMU_Match_IOMMU_AndClass
            {
                # <params>
                local readonly str_class="${arr_class[$int_key]}"
                # local readonly str_device_ID="${arr_device_ID[$int_key]}"
                local readonly str_device_name="${arr_device_name[$int_key]}"
                local readonly str_driver="${arr_driver[$int_key]}"
                local readonly str_hardware_ID="${arr_hardware_ID[$int_key]}"
                local readonly str_slot_ID="${arr_slot_ID[$int_key]}"
                # local readonly str_vendor_ID="${arr_vendor_ID[$int_key]}"
                local readonly str_vendor_name="${arr_vendor_name[$int_key]}"

                local readonly str_domain_ID=$( echo "${str_slot_ID}" | cut -d ':' -f 1 )

                # <remarks> Regex: check if value is decimal or hexadecimal and greater than zero </remarks>
                local readonly str_regex='[a-fA-F1-9]'

                # <remarks> Output statement </remarks>
                declare -ar arr_something=(
                    "Slot ID:\t'${str_slot_ID}'"
                    "Vendor name:\t'${str_vendor_name}'"
                    "Device name:\t'${str_device_name}'"
                    "Class/Type:\t'${str_class}'"
                    # "Hardware ID:\t'${str_hardware_ID}'"
                    # "Vendor ID:\t'${str_vendor_ID}'"
                    # "Device ID:\t'${str_device_ID}'"
                    "Kernel driver:\t'${str_driver}'"
                )
                # </params>

                # <remarks> Match IOMMU group </remarks>
                if [[ "${int_IOMMU}" -eq "${int_this_IOMMU_ID}" ]]; then

                    # <remarks> External PCI devices have domain IDs of '01' or greater. </remarks>
                    if [[ "${str_domain_ID}" =~ ${str_regex} ]]; then
                        bool_IOMMU_has_external_domain=true
                    fi

                    local str_class=$( echo "${arr_class[$int_key]}" | tr '[:upper:]' '[:lower:]' )
                    PrintArray "arr_something"

                    # <remarks> Match Class </remarks>
                    case "${str_class}" in
                        "graphics" | "vga" | "video" )
                            bool_IOMMU_has_VGA=true
                            # bool_IOMMU_VFIO_PCI=true
                            ;;

                        "usb" )
                            bool_IOMMU_has_USB=true
                            bool_IOMMU_PCI_STUB=true
                            ;;
                    esac
                fi

                return 0
            }

            function Select_IOMMU_Prompt
            {
                # <params>
                local readonly str_output_do_select="Select IOMMU group '${int_this_IOMMU_ID}'?"
                local readonly str_output_skip_select="Skipped IOMMU group '${int_this_IOMMU_ID}'."
                # </params>

                # <remarks> Append to list a valid array or empty value. </remarks>
                if "${bool_IOMMU_has_external_domain}" && ReadInput "${str_output_do_select}"; then
                    if "${bool_IOMMU_has_USB}"; then
                        arr_IOMMU_PCI_STUB+=( "${int_this_IOMMU_ID}" )
                    else
                        arr_IOMMU_PCI_STUB+=( "" )
                    fi

                    if "${bool_IOMMU_has_VGA}"; then
                        arr_IOMMU_VFIO_PCI+=( "" )
                        arr_IOMMU_VFIO_PCI_with_VGA+=( "${int_this_IOMMU_ID}" )
                    else
                        arr_IOMMU_VFIO_PCI+=( "${int_this_IOMMU_ID}" )
                        arr_IOMMU_VFIO_PCI_with_VGA+=( "" )
                    fi
                else
                    arr_IOMMU_VFIO_PCI+=( "" )
                    arr_IOMMU_PCI_STUB+=( "" )
                    arr_IOMMU_VFIO_PCI_with_VGA+=( "" )
                    echo -e "${str_output_skip_select}"
                fi

                return 0
            }

            # <params>
            declare -g bool_VFIO_has_IOMMU=false
            local readonly str_output="Reviewing IOMMU groups..."
            local readonly int_IOMMU_max=$( basename $( ls -1v /sys/kernel/iommu_groups/ | sort -hr | head -n1 ) )
            local readonly var_get_IOMMU='seq 0 "${int_IOMMU_max}"'
            declare -a arr_IOMMU_PCI_STUB arr_IOMMU_VFIO_PCI arr_IOMMU_VFIO_PCI_with_VGA
            declare -ar arr_this_IOMMU=( $( eval "${var_get_IOMMU}" ) )
            # </params>

            echo -e "${str_output}"

            for int_this_IOMMU_ID in "${arr_this_IOMMU[@]}"; do
                local bool_IOMMU_has_external_domain=false
                local bool_IOMMU_PCI_STUB=false
                # local bool_IOMMU_VFIO_PCI=false
                local bool_IOMMU_has_USB=false
                local bool_IOMMU_has_VGA=false

                for int_key in ${!arr_IOMMU[@]}; do
                    declare -i int_IOMMU="${arr_IOMMU[$int_key]}"
                    Select_IOMMU_Match_IOMMU_AndClass
                done

                Select_IOMMU_Prompt
            done

            # TOOD: create a function that takes in a string, which is the name of another parameter (like a pointer) and perform validation given the var type (check prefix var, str, int, arr, etc.)
            # TODO: create single line strings of arrays of drivers and HW IDs, with delimiters (commas)
            # arr_IOMMU_VFIO_PCI
            # str_driverListForVFIO
            # str_driverListForSTUB
            # str_HWID_list_forVFIO

            # <remarks> Check if list is empty </remarks>
            declare -a arr=( "${arr_IOMMU_VFIO_PCI[@]}" )
            CheckIfArrayIsEmpty && bool_VFIO_has_IOMMU=true

            AppendPassOrFail "${str_output}"
            echo
            return "${int_exit_code}"
        }
    # </code>

    # <summary> Business functions: Main setup </summary>
    # <code>
        function Multiboot_VFIO
        {
            # <params>
            local readonly str_file1="/etc/default/grub"
            local readonly str_file2="/etc/grub.d/proxifiedScripts/custom"
            local readonly str_file1_backup="etc_default_grub"
            local readonly str_file2_backup="etc_grub.d_proxifiedScripts_custom"
            # </params>

            GoToScriptDir && cd "${str_files_dir}"

            if ! CheckIfFileExists "${str_file1_backup}" || CheckIfFileExists "${str_file2_backup}"; then
                return "$?"
            fi


        }

        function Static_VFIO
        {
            # <params>
            declare -a arr_file1_contents arr_file2_contents arr_file3_contents arr_file4_contents arr_file5_contents
            local readonly str_file1="/etc/default/grub"
            local readonly str_file2="/etc/initramfs-tools/modules"
            local readonly str_file3="/etc/modprobe.d/pci-blacklists.conf"
            local readonly str_file4="/etc/modprobe.d/vfio.conf"
            local readonly str_file5="/etc/modules"
            local readonly str_file1_backup="etc_default_grub"
            local readonly str_file2_backup="etc_initramfs-tools_modules"
            local readonly str_file3_backup="etc_modprobe.d_pci-blacklists.conf"
            local readonly str_file4_backup="etc_modprobe.d_vfio.conf"
            local readonly str_file5_backup="etc_modules"

            local readonly str_driver_VFIO_PCI="vfio-pci"
            local str_GRUB="GRUB_CMDLINE_LINUX_DEFAULT="
            local readonly str_GRUB_blacklist="modprobe.blacklist="
            local readonly str_GRUB_PCI_STUB="pci-stub.ids="
            local readonly str_GRUB_VFIO_PCI="vfio_pci.ids="
            local readonly str_modprobe_blacklist="blacklist "
            local readonly str_modules_VFIO_PCI="vfio_pci ids="
            local readonly str_initramfs_modules_VFIO_PCI="options ${str_modules_VFIO_PCI}"
            # </params>

            # <remarks> Check if backup files exist. </remarks>
            GoToScriptDir && cd "${str_files_dir}"

            if ! CheckIfFileExists "${str_file1_backup}" || CheckIfFileExists "${str_file2_backup}" || CheckIfFileExists "${str_file3_backup}" || CheckIfFileExists "${str_file4_backup}"|| CheckIfFileExists "${str_file5_backup}"; then
                return "${?}"
            fi

            # <remarks> Backup existing system files. </remarks>
            # NOTE: will a conflict exist should backup files exist in given directories (example: modprobe.d) and not others (ex: grub)
            CreateBackupFile "${str_file1_backup}"
            CreateBackupFile "${str_file2_backup}"
            CreateBackupFile "${str_file3_backup}"
            CreateBackupFile "${str_file4_backup}"
            CreateBackupFile "${str_file5_backup}"

            # <remarks> GRUB </remarks>
            local str_GRUB_temp=""
            CheckIfVarIsVar "${str_GRUB_Allocate_CPU}" &> /dev/null && str_GRUB_temp+="${str_GRUB_Allocate_CPU}"
            CheckIfVarIsVar "${str_GRUB_hugepages}" &> /dev/null && str_GRUB_temp+=" ${str_GRUB_hugepages}"

            if CheckIfVarIsVar "${str_driverListForVFIO}" &> /dev/null; then
                str_GRUB_temp+=" ${str_GRUB_blacklist}${str_driverListForVFIO}"
            fi

            if CheckIfVarIsVar "${str_HWID_list_forSTUB}" &> /dev/null; then
                str_GRUB_temp+=" ${str_GRUB_PCI_STUB}${str_HWID_list_forSTUB}"
            fi

            if CheckIfVarIsVar "${str_HWID_list_forVFIO}" &> /dev/null; then
                str_GRUB_temp+=" ${str_GRUB_VFIO_PCI}${str_HWID_list_forVFIO}"
            fi

            readonly str_GRUB+="\"${str_GRUB_temp}\""

            # if grep -iF "${str_GRUB}"*; then
            #     while read var_line; do
                    


            #     done >> "${str_file1}"
            # fi

            # <remarks> Initramfs </remarks>

            # <remarks> Modules </remarks>

            # <remarks> Modprobe: blacklists </remarks>

            # <remarks> Modprobe: conf </remarks>

            return 0
        }

        function Setup_VFIO
        {
            # <params>

            # </params>

            # diff between static and multiboot => static: all IOMMU for VFIO with PCI STUB devices will be binded to VFIO PCI driver? append only to GRUB and system files.
            # multiboot: PCI STUB devices will use PCI STUB driver? append only GRUB and multiple GRUB entries

            return 0
        }

        function UpdateExisting_VFIO
        {
            return 0
        }
    # </code>

    # <summary> Business functions: Pre/Post setup </summary>
    # <code>
        # <params>
        declare -gr var_get_first_valid_user='getent passwd {1000..60000} | cut -d ":" -f 1'
        declare -gr str_username=$( eval "${var_get_first_valid_user}" )
        declare -g bool_is_setup_evdev=false
        declare -g bool_is_setup_hugepages=false
        # </params>

        # <summary> Add user to necessary user groups. </summary>
        function AddUserToGroups
        {
            function AddUserToGroups_Main
            {
                # <remarks> Add user(s) to groups. </remarks>
                adduser "${str_username}" "input" || return 1
                adduser "${str_username}" "libvirt" || return 1
                return 0
            }

            # <params>
            local readonly str_output="Adding user to groups..."
            # </params>

            echo
            echo -e "${str_output}"
            AddUserToGroups_Main
            AppendPassOrFail "${str_output}"
            return "${int_exit_code}"
        }

        # <summary> isolcpus: Ask user to allocate host CPU cores (and/or threads), to reduce host overhead, and improve both host and virtual machine performance. </summary
        function Allocate_CPU
        {
            function Allocate_CPU_Main
            {
                # <params>
                local readonly var_get_all_cores='seq 0 $(( ${int_total_cores} - 1 ))'
                local readonly var_get_total_threads='cat /proc/cpuinfo | grep "siblings" | uniq | grep -o "[0-9]\+"'
                local readonly var_get_total_cores='cat /proc/cpuinfo | grep "cpu cores" | uniq | grep -o "[0-9]\+"'
                declare -ir int_total_cores=$( eval "${var_get_total_cores}" )
                declare -ir int_total_threads=$( eval "${var_get_total_threads}" )
                # </params>

                # <summary> Set maximum number of cores allocated to host machine. </summary>
                    # <params>
                    declare -ar arr_all_cores=( $( eval "${var_get_all_cores}" ) )
                    declare -i int_host_cores=1
                    # </params>

                    # <remarks> quad-core or greater CPU </remarks>
                    if [[ "${int_total_cores}" -ge 4 ]]; then
                        readonly int_host_cores=2

                    # <remarks> double-core/triple-core CPU </remarks>
                    elif [[ "${int_total_cores}" -le 3 && "${int_total_cores}" -ge 2 ]]; then
                        readonly int_host_cores

                    # <remarks> If single-core CPU, fail. </remarks>
                    else
                        readonly int_host_cores
                        false
                        AppendPassOrFail "${str_output}"
                        return "${int_exit_code}"
                    fi

                # <summary> Get thread sets, for host and virtual machines. </summary>
                    # <params>
                    local readonly var_get_host_cores='seq 0 $(( ${int_host_cores} - 1 ))'
                    local readonly var_get_SMT_factors='seq 0 $(( ${int_SMT_factor} - 1 ))'
                    local readonly var_get_thread='$(( int_core + ( int_SMT_factor * int_total_cores ) ))'
                    local readonly var_get_virt_cores='seq ${int_host_cores} $(( ${int_total_cores} - 1 ))'

                    declare -ar arr_host_cores=( $( eval "${var_get_host_cores}" ) )
                    declare -a arr_host_threads=()
                    declare -ar arr_virt_cores=( $( eval "${var_get_virt_cores}" ) )
                    declare -a arr_virt_threads=()
                    declare -i int_SMT_factor=$(( "${int_total_threads}" / "${int_total_cores}" ))
                    declare -a arr_SMT_factors=( $( eval "${var_get_SMT_factors}" ) )

                    declare -g str_host_thread_sets
                    declare -g str_virt_thread_sets
                    # </params>

                    function GetThreadByCoreAnd_SMT
                    {
                        int_thread=$(( int_core + ( int_SMT_factor * int_total_cores ) ))
                    }

                    for int_SMT_factor in "${arr_SMT_factors[@]}"; do
                        # <remarks> Reset params </remarks>
                        declare -a arr_host_threads_sets=()
                        declare -a arr_virt_threads_sets=()
                        declare -i int_thread

                        # <remarks> Find thread sets for host machine. </remarks>
                        for int_core in "${arr_host_cores[@]}"; do
                            GetThreadByCoreAnd_SMT
                            arr_host_threads+=( "${int_thread}" )
                            arr_host_threads_sets+=( "${int_thread}" )
                        done

                        # <remarks> Find thread sets for virtual machines. </remarks>
                        for int_core in "${arr_virt_cores[@]}"; do
                            GetThreadByCoreAnd_SMT
                            arr_virt_threads+=( "${int_thread}" )
                            arr_virt_threads_sets+=( "${int_thread}" )
                        done

                        # <remarks> Save thread sets to delimited list. </remarks>
                        declare -i int_set_first_thread="${arr_host_threads_sets[0]}"
                        declare -i int_set_last_thread="${arr_host_threads_sets[-1]}"
                        local str_thread_set="${int_set_first_thread}"

                        if [[ "${int_set_first_thread}" -ne "${int_set_last_thread}" ]]; then
                            local str_thread_set="${int_set_first_thread}-${int_set_last_thread}"
                        fi

                        str_host_thread_sets+="${str_thread_set},"

                        declare -i int_set_first_thread="${arr_virt_threads_sets[0]}"
                        declare -i int_set_last_thread="${arr_virt_threads_sets[-1]}"
                        local str_thread_set="${int_set_first_thread}"

                        if [[ "${int_set_first_thread}" -ne "${int_set_last_thread}" ]]; then
                            local str_thread_set="${int_set_first_thread}-${int_set_last_thread}"
                        fi

                        str_virt_thread_sets+="${str_thread_set},"
                    done

                    # <remarks> Truncate last delimiter. </remarks>
                    if [[ ${str_host_thread_sets: -1} == "," ]]; then
                        str_host_thread_sets=${str_host_thread_sets::-1}
                    fi

                    # <remarks> Ditto. </remarks>
                    if [[ ${str_virt_thread_sets: -1} == "," ]]; then
                        str_virt_thread_sets=${str_virt_thread_sets::-1}
                    fi

                    # <remarks> Save output </remarks>
                    readonly str_host_thread_sets str_virt_thread_sets

                # <summary> Find CPU mask. </summary>
                    # <remarks>
                    # save output to string for cpuset and cpumask
                    # example:
                    #   host 0-1,8-9
                    #   virt 2-7,10-15
                    #
                    # information
                    # cores     bit masks       mask
                    # 0-7       0b11111111      FF      # total cores
                    # 0,4       0b00010001      11      # host cores
                    #
                    # 0-11      0b111111111111  FFF     # total cores
                    # 0-1,6-7   0b000011000011  C3      # host cores
                    #
                    # </remarks>

                    # <params>
                    local readonly var_get_hexadecimal_mask_from_decimal='echo "obase=16; ${int_thread_decimal}" | bc'
                    declare -i int_host_threads_hexadecimal_mask=0
                    declare -i int_total_threads_hexadecimal_mask=0
                    # </params>

                    # <remarks> Add each decimal mask to sum. </remarks>
                    for int_thread in "${arr_host_threads[@]}"; do
                        declare -i int_thread_decimal=$(( 2 ** ${int_thread} ))
                        declare -i int_thread_hexadecimal_mask=$( eval "${var_get_hexadecimal_mask_from_decimal}" )
                        int_host_threads_hexadecimal_mask+="${int_thread_hexadecimal_mask}"
                    done

                    for int_thread in "${arr_total[@]}"; do
                        declare -i int_thread_decimal=$(( 2 ** ${int_thread} ))
                        declare -i int_thread_hexadecimal_mask=$( eval "${var_get_hexadecimal_mask_from_decimal}" )
                        int_host_threads_hexadecimal_mask+="${int_thread_hexadecimal_mask}"
                    done

                    # <remarks> Save changes, convert hexadecimal mask into hexadecimal. </remarks>
                    readonly int_host_threads_hexadecimal_mask
                    declare -gr str_host_threads_hexadecimal=$( printf '%x\n' $int_host_threads_hexadecimal_mask )
                    declare -ir int_total_threads_hexadecimal_mask=$(( ( 2 ** ${int_total_threads} ) - 1 ))
                    declare -gr str_total_threads_hexadecimal=$( printf '%x\n' $int_total_threads_hexadecimal_mask )

                declare -a arr_output=(
                    "Allocated to Host\t${str_host_thread_sets}"
                    "Allocated to guest:\t${str_virt_thread_sets}"
                )

                PrintArray
                echo

                # <remarks> Save changes. </remarks>
                declare -gr str_GRUB_Allocate_CPU="isolcpus=${str_virt_thread_sets} nohz_full=${str_virt_thread_sets} rcu_nocbs=${str_virt_thread_sets}"
                return 0
            }

            # <params>
            local readonly str_output="Allocating CPU threads..."
            # </params>

            echo
            echo -e "${str_output}"
            Allocate_CPU_Main
            AppendPassOrFail "${str_output}"
            return "${int_exit_code}"
        }

        # <summary> Hugepages: Ask user to allocate host memory (RAM) to 'hugepages', to eliminate the need to defragement memory, to reduce host overhead, and to improve both host and virtual machine performance. </summary
        function Allocate_RAM
        {
            function Allocate_RAM_Main
            {
                # <params>
                declare -ar arr_choices=(
                    "2M"
                    "1G"
                )

                declare -gi int_huge_page_count=0
                declare -gi int_huge_page_kbit_size=0
                declare -gi int_huge_page_max_kbit_size=0
                declare -gir int_huge_page_min_kbit_size=4194304
                declare -gi int_huge_page_max=0
                declare -gi int_huge_page_min=0
                declare -g str_huge_page_byte_prefix=""
                declare -g str_hugepages_QEMU=""

                local readonly str_output1="Hugepages is a feature which statically allocates system memory to pagefiles.\n\tVirtual machines can use Hugepages to a peformance benefit.\n\tThe greater the Hugepage size, the less fragmentation of memory, and the less latency/overhead of system memory-access.\n\t${var_yellow}NOTE:${var_reset_color} It is recommended to use a size which is a multiple of an individual memory channel/stick.\n\t${var_yellow}Example:${var_reset_color} Four (4) channels of 8 GB each, use 1x, 2x, or 3x (8 GB, 16 GB, or 24 GB).\n"
                local readonly str_output2="Setup Hugepages?"
                local readonly str_output3="Enter size of Hugepages (bytes):"
                local readonly var_get_host_max_mem='cat /proc/meminfo | grep MemTotal | cut -d ":" -f 2 | cut -d "k" -f 1'
                # </params>

                if ! CheckIfVarIsNum "${int_max_mem}" &> /dev/null; then
                    local readonly str_output_could_not_parse_memory="${var_prefix_error} Could not parse system memory."
                    echo -e "${str_output_could_not_parse_memory}"
                fi

                # <remarks> Ask user to proceed. </remarks>
                echo -e "${str_output1}"
                ReadInput "${str_output2}" || return "${int_code_skipped_operation}"
                var_input=""
                ReadMultipleChoiceIgnoreCase "${str_output3}" "${arr_choices[@]}" || return "${?}"
                # echo "${var_input}"
                str_huge_page_byte_prefix="${var_input}"
                int_huge_page_max_kbit_size=$( eval "${var_get_host_max_mem}" )

                # <remarks> Validate hugepage size and byte-size. </remarks>
                case "${str_huge_page_byte_prefix}" in
                    "${arr_choices[0]}" )
                        readonly int_huge_page_kbit_size=2048
                        readonly int_huge_page_min=2
                        ;;
                    "${arr_choices[1]}" )
                        readonly int_huge_page_kbit_size=1048576
                        readonly int_huge_page_min=1
                        ;;
                    * )
                        return "${?}"
                        ;;
                esac

                # <remarks> Get values. </remarks>
                int_huge_page_max=$(( $int_huge_page_max_kbit_size - $int_huge_page_min_kbit_size ))
                readonly int_huge_page_max=$(( $int_huge_page_max / $int_huge_page_kbit_size ))
                local readonly str_output4="Enter number of Hugepages (num * ${str_huge_page_byte_prefix})"

                # <remarks> Ask user for preferred amount. </remarks>
                ReadInputFromRangeOfTwoNums "${str_output4}" "${int_huge_page_min}" "${int_huge_page_max}" || return "${?}"
                readonly int_huge_page_count="${var_input}"

                # <remarks> Save changes. </remarks>
                declare -gr int_alloc_mem_hugepages=$(( $int_huge_page_count * $int_huge_page_kbit_size ))
                declare -gr str_GRUB_hugepages="default_hugepagesz=${str_huge_page_byte_prefix} hugepagesz=${str_huge_page_byte_prefix} hugepages=${int_huge_page_count}"
                bool_is_setup_hugepages=true
                return 0
            }

            # <params>
            local readonly str_output="Executing Hugepages setup..."
            # </params>

            echo
            echo -e "${str_output}"
            Allocate_RAM_Main
            AppendPassOrFail "${str_output}"
            return "${int_exit_code}"
        }

        # <summary> Ask user to setup audio loopback from the host's Line-in to active audio output. Useful for virtual machines with sound-cards (example: Creative SoundBlaster). </summary>
        function HostAudioLineIn
        {
            return 0
        }

        function LibvirtHooks
        {
            return 0
        }

        # <summary> libvirt-qemu: Append necessary changes to QEMU system file, including user groups, Evdev, Hugepages, and NVRAM (for UEFI VMs). </summary>
        function Modify_QEMU
        {
            function Modify_QEMU_Main
            {
                # <params>
                declare -a arr_file1_evdev_cgroups=()
                declare -ar arr_file1_default_cgroups=(
                    "        \"/dev/null\", \"/dev/full\", \"/dev/zero\","
                    "        \"/dev/random\", \"/dev/urandom\","
                    "        \"/dev/ptmx\", \"/dev/kvm\","
                    "        \"/dev/rtc\", \"/dev/hpet\""
                )

                local readonly str_daemon1="libvirtd"
                local readonly str_daemon1_packages="qemu"
                local readonly str_file1="/etc/libvirt/qemu.conf"
                local readonly str_file1_backup="./files/etc_libvirt_qemu.conf"
                # local readonly var_set_event_device='"        \"/dev/input/by-id/${str_event_device}\",'
                # </params>

                # <remarks> Backup system file and grab clean file from repository. </remarks>
                CreateBackupFile "${str_file1}"
                GoToScriptDir || return "${?}"
                CheckIfFileExists "${str_file1_backup}" || return "${?}"
                cp "${str_file1_backup}" "${str_file1}" || return 1

                # <remarks> Get Event devices. </remarks>
                if "${bool_is_setup_evdev}"; then
                    for str_event_device in "${arr_event_devices[@]}"; do
                        arr_file1_evdev_cgroups+=( "        \"/dev/input/by-id/${str_event_device}\"," )
                    done

                    for str_event_device in "${arr_input_devices[@]}"; do
                        arr_file1_evdev_cgroups+=( "        \"/dev/input/by-id/${str_event_device}\"," )
                    done
                fi

                # <remarks> Save changes. </remarks>
                readonly arr_file1_evdev_cgroups

                # <remarks> Begin append. </remarks>
                arr_file1_contents=(
                    ""
                    ""
                    "#"
                    "# Generated by '${str_full_repo_name}'"
                    "#"
                    "# WARNING: Any modifications to this file will be modified by '${str_repo_name}'"
                    "#"
                    "# Run 'systemctl restart ${str_daemon1}.service' to update."
                    "#"
                )

                # <remarks> Adds or omits specific user to use Evdev. </remarks>
                local readonly str_output4="Adding user..."

                if CheckIfVarIsVar "${str_username}" &> /dev/null; then
                    arr_file1_contents+=(
                        ""
                        "### User permissions ###"
                        "user = \"${str_username}\""
                        "group = \"user\""
                    )
                else
                    arr_file1_contents+=(
                        ""
                        "### User permissions ###"
                        "#user = \"user\""
                        "#group = \"user\""
                    )

                    ( return "${int_code_skipped_operation}" )
                fi

                AppendPassOrFail "${str_output4}"

                # <remarks> Adds or omits validation for Hugepages. </remarks>
                local readonly str_output5="Adding Hugepages..."

                if "${bool_is_setup_hugepages}"; then
                    arr_file1_contents+=(
                        ""
                        "### Hugepages ###"
                        "hugetlbfs_mount = \"/dev/hugepages\""
                    )
                else
                    arr_file1_contents+=(
                        ""
                        "### Hugepages ###"
                        "#hugetlbfs_mount = \"/dev/hugepages\""
                    )

                    ( return "${int_code_skipped_operation}" )
                fi

                AppendPassOrFail "${str_output5}"

                # <remarks> Adds or omits Event devices. </remarks>
                local readonly str_output6="Adding Evdev..."

                if "${bool_is_setup_evdev}"; then
                    arr_file1_contents+=(
                        ""
                        "### Devices ###"
                        "cgroup_device_acl = ["
                        "${arr_file1_evdev_cgroups[@]}"
                        "${arr_file1_default_cgroups[@]}"
                        "]"
                    )
                else
                    arr_file1_contents+=(
                        ""
                        "### Devices ###"
                        "cgroup_device_acl = ["
                        "${arr_file1_default_cgroups[@]}"
                        "]"
                    )

                    ( return "${int_code_skipped_operation}" )
                fi

                AppendPassOrFail "${str_output6}"

                # <remarks> Adds NVRAM for EFI kernels in UEFI virtual machines. </remarks>
                arr_file1_contents+=(
                    ""
                    "nvram = ["
                    "        \"/usr/share/OVMF/OVMF_CODE.fd:/usr/share/OVMF/OVMF_VARS.fd\","
                    "        \"/usr/share/OVMF/OVMF_CODE.secboot.fd:/usr/share/OVMF/OVMF_VARS.fd\","
                    "        \"/usr/share/AAVMF/AAVMF_CODE.fd:/usr/share/AAVMF/AAVMF_VARS.fd\","
                    "        \"/usr/share/AAVMF/AAVMF32_CODE.fd:/usr/share/AAVMF/AAVMF32_VARS.fd\""
                    "]"
                )

                # <remarks> Save changes. </remarks>
                readonly arr_file1_contents
                declare -a arr_file=( "${arr_file1_contents[@]}" )
                WriteFile "${str_file1}" || return "${?}"

                # <remarks> Check if daemon exists and restart it. </remarks>
                CheckIfPackageExists "${str_daemon1_packages}" || return "${?}"
                CheckIfDaemonIsActiveOrNot "${str_daemon1}" &> /dev/null || ( sudo systemctl enable "${str_daemon1}" || return 1 )

                local readonly var_restart_daemon='sudo systemctl restart "${str_daemon1}"'
                TryThisXTimesBeforeFail "${var_restart_daemon}"
                return "${?}"
            }

            # <params>
            local readonly str_output="Appending changes to libvirt-qemu..."
            # </params>

            echo
            echo -e "${str_output}"
            Modify_QEMU_Main
            AppendPassOrFail "${str_output}"
            return "${int_exit_code}"
        }

        # <summary> zramswap: Ask user to setup a swap partition in host memory, to reduce swapiness to existing host swap partition(s)/file(s), and reduce chances of memory exhaustion as host over-allocates memory. </summary>
        function RAM_Swapfile
        {
            function RAM_Swapfile_Install
            {
                # <params>
                local readonly str_user_name1="foundObjects"
                local readonly str_repo_name1="zram-swap"
                local readonly str_full_repo1="${str_user_name1}/${str_repo_name1}"
                local readonly str_script_name1="install.sh"
                # </params>

                GoToScriptDir
                UpdateOrCloneGitRepo "${str_repos_dir}" "${str_full_repo1}" "${str_user_name1}"
                cd "${str_repos_dir}${str_full_repo1}" || return "${?}"
                CheckIfFileExists "${str_script_name1}" || return "${?}"
                sudo bash "${str_script_name1}"
                return "${?}"
            }

            function RAM_Swapfile_Modify
            {
                # <params>
                declare -ir int_max_mem=$(cat /proc/meminfo | grep MemTotal | cut -d ":" -f 2 | cut -d "k" -f 1 )
                local readonly str_file1="/etc/default/zram-swap"
                local readonly str_match_line1="_zram_fraction="
                local readonly var_command='cat "${str_file1}"'
                local readonly var_enable_all_swap='sudo swapon -a'
                local readonly var_restart_daemon='sudo systemctl restart zram-swap'
                declare -a arr_file=( $( eval "${var_command}" ) )
                # </params>

                # <remarks> Replace matching line with comment of line </remarks>
                for int_key in "${!arr_file[@]}"; do
                    if [[ "${arr_file[$int_key]}" == *"${str_match_line1}"* ]]; then
                        arr_file[$int_key]="#${arr_file[$int_key]}"
                    fi
                done

                if ! CheckIfVarIsNum "${int_max_mem}" &> /dev/null; then
                    local readonly str_output_could_not_parse_memory="${var_prefix_error} Could not parse system memory."
                    echo -e "${str_output_could_not_parse_memory}"
                    return 1
                fi

                if CheckIfVarIsNum "${int_alloc_mem_hugepages}" &> /dev/null; then
                    declare -ir int_usable_mem=$(( ( int_max_mem - int_alloc_mem_hugepages ) / 2 ))
                else
                    declare -ir int_usable_mem=$(( int_max_mem / 2 ))
                fi

                declare -i int_denominator=$( printf "%.0f" $( echo "scale=2;${int_max_mem}/${int_usable_mem}" | bc ) )

                # <remarks> Round down to nearest even number. </remarks>
                if [[ $( expr $int_denominator % 2 ) -eq 1 ]]; then
                    (( int_denominator-- ))
                fi

                readonly int_denominator

                # <remarks> Is fraction positive non-zero and not equal to one. </remarks>
                if [[ "${int_denominator}" -gt 1 ]]; then
                    local readonly str_fraction="1/${int_denominator}"

                    arr_file+=(
                        ""
                        "#"
                        "# Generated by '${str_full_repo_name}'"
                        "#"
                        "# WARNING: Any modifications to this file will be modified by '${str_repo_name}'"
                        "${str_match_line1}\"${str_fraction}\""
                    )
                fi

                OverwriteFile "${str_file1}" || return "${?}"
                eval "${var_restart_daemon}" || return "${?}"
                eval "${var_enable_all_swap}" || return "${?}"

                return "${?}"
            }

            # <params>
            local readonly str_output="Installing zram-swap..."
            # </params>

            echo
            echo -e "${str_output}"

            if ! RAM_Swapfile_Install || ! RAM_Swapfile_Modify; then
                false
            fi

            AppendPassOrFail "${str_output}"
            return "${int_exit_code}"
        }

        # <summary> Evdev: Ask user to setup a virtual Keyboard-Video-Mouse swich (excluding the Video). Will allow a user to swap between active virtual machines and host, with the use of a pre-defined macro (example: 'L-CTRL' + 'R-CTRL'). </summary>
        function Virtual_KVM
        {
            function Virtual_KVM_Main
            {
                # <params>
                declare -ga arr_event_devices=()
                declare -ga arr_input_devices=()

                local readonly str_output1="Evdev (Event Devices) is a method of creating a virtual KVM (Keyboard-Video-Mouse) switch between host and VM's.\n\tHOW-TO: Press 'L-CTRL' and 'R-CTRL' simultaneously.\n"
                local readonly str_output2="Setup Evdev?"

                local readonly var_get_event_devices='ls -l /dev/input/by-id | cut -d "/" -f2 | grep -v "total 0"'
                local readonly var_get_input_devices='ls /dev/input/by-id'
                # </params>

                # <remarks> Ask user to proceed. </remarks>
                echo -e "${str_output1}"
                ReadInput "${str_output2}" || return "${int_code_skipped_operation}"

                # <remarks> Get all devices for Evdev. </remarks>
                readonly arr_event_devices=( $( eval "${var_get_event_devices}") )
                readonly arr_input_devices=( $( eval "${var_get_input_devices}") )

                # <remarks> Early-exit. </remarks>
                if ! CheckIfVarIsVar "${arr_event_devices[@]}" && ! CheckIfVarIsVar "${var_get_input_devices[@]}"; then
                    return 1
                fi

                bool_is_setup_evdev=true
                return 0
            }

            # <params>
            local readonly str_output="Executing Evdev setup..."
            # </params>

            echo
            echo -e "${str_output}"
            Virtual_KVM_Main
            AppendPassOrFail "${str_output}"
            return "${int_exit_code}"
        }

        # <summary> LookingGlass: Ask user to setup direct-memory-access of video framebuffer from virtual machine to host. NOTE: Only supported for Win 7/10/11 virtual machines. </summary>
        function VirtualVideoCapture
        {
            # TODO:
            # -add disclaimer for end user in both README and output
            # -point to LookingGlass website

            function VirtualVideoCapture_Main
            {
                # <remarks> reference: https://looking-glass.io/docs/B6/install/#client-install </remarks>

                # <params>
                local readonly str_user_name1="gnif"
                local readonly str_repo_name1="LookingGlass"
                local readonly str_full_repo1="${str_user_name1}/${str_repo_name1}"
                local readonly str_dependencies="cmake gcc g++ clang libegl-dev libgl-dev libgles-dev libfontconfig-dev libgmp-dev libspice-protocol-dev make nettle-dev pkg-config"
                # </params>

                # <remarks> Install dependencies. </remarks>
                if [[ "${str_package_manager}" == "apt" ]]; then
                    InstallPackage "${str_dependencies}" || return "${?}"
                fi

                # <remarks> Get repo </remarks>
                GoToScriptDir
                UpdateOrCloneGitRepo "${str_repos_dir}" "${str_full_repo1}" "${str_user_name1}"
                cd "${str_repos_dir}${str_full_repo1}" || return "${?}"

                # <remarks> Build client </remarks>
                mkdir client/build || return 1
                cd client/build || return 1
                cmake ../ || return 1
                make || return 1

                # <remarks> Conclude build as root or user. </remarks>
                if $bool_is_user_root; then
                    make install || return 1
                else
                    cmake -DCMAKE_INSTALL_PREFIX=~/.local .. && make install
                fi

                return 0
            }

            # <params>
            local readonly str_output="Executing LookingGlass setup..."
            # </params>

            echo
            echo -e "${str_output}"
            VirtualVideoCapture_Main
            AppendPassOrFail "${str_output}"
            return "${int_exit_code}"
        }

        # <summary> Scream: Ask user to setup audio loopback from virtual machine to host. NOTE: Only supported for Win 7/10/11 virtual machines. </summary>
        # function VirtualAudioCapture
        # {
        #     return 0
        # }
    # </code>

    # <summary> Main </summary>
    # <code>
        # TODO: debug and fix usage (options and arguments)

        function PrintUsage
        {
            # <params>
            IFS=$'\n'
            local readonly var_get_script_name='basename "${0}"'
            local readonly str_script_name=$( eval "${var_get_script_name}" )
            local readonly str_opt_full_setup="-f, --full\texecute pre-setup, VFIO setup, and post-setup"
            local readonly str_opt_help="-h, --help\tdisplay this help and exit"
            local readonly str_opt_multiboot_VFIO_setup="-m, --multiboot\texecute preferred VFIO setup: modify GRUB boot options only (excluding GRUB file and system files)"
            local readonly str_opt_post_setup="-P, --post\texecute post-setup (LookingGlass, Scream)"
            local readonly str_opt_pre_setup="-p, --pre\texecute pre-setup (allocate CPU, hugepages, zramswap, Evdev)"
            local readonly str_opt_static_VFIO_setup="-s, --static\texecute preferred VFIO setup: modify GRUB file and system files only"
            local readonly str_opt_update_VFIO_setup="-u, --update\tdetect existing VFIO setup, execute new VFIO setup, and apply changes"
            local readonly str_arg_silent="-S, --silent\tdo not prompt before execution"
            local readonly str_arg_file="-F, --file\tparse PCI from file"
            local readonly str_arg_online="-O, --online\tparse PCI from internet"

            declare -ar arr_usage=(
                "Usage:\t${str_script_name} [OPTION] [ARGUMENTS]"
                "\tor ${str_script_name} [OPTION] -S"
                "\tor ${str_script_name} [d/m/s/u] -F [FILE_NAME]"
                "\tor ${str_script_name} [d/m/s/u] -o"
                "\nRequired variables:"
                "\t${str_script_name}"
                "\nOptional variables:"
                "\t${str_opt_help}"
                "\t${str_opt_multiboot_VFIO_setup}"
                "\t${str_opt_static_VFIO_setup}"
                "\t${str_opt_update_VFIO_setup}"
                "\t${str_opt_post_setup}"
                "\t${str_opt_pre_setup}"
                "\t${str_opt_full_setup}"
                "\nArguments:"
                "\t${str_arg_silent}"
                "\t${str_arg_file}"
                "\t${str_arg_online}"
            )
            # </params>

            # <remarks> Display usage. </remarks>
            for str_line in ${arr_usage[@]}; do
                echo -e "${str_line}"
            done

            return 0
        }

        function GetUsage
        {
            # <params>
            declare -gr arr_usage_opt=(
                "-h"
                "--help"
                "-m"
                "--multiboot"
                "-f"
                "--full"
                "-P"
                "--post"
                "-p"
                "--pre"
                "-s"
                "--static"
                "-u"
                "--update"
            )

            declare -gr arr_usage_args=(
                "-S"
                "--silent"
                "-F"
                "--file"
                "-o"
                "--online"
            )

            if CheckIfVarIsVar "${1}" &> /dev/null; then
                case "${1}" in
                    "${arr_usage_opt[0]}" | "${arr_usage_opt[1]}" )
                        bool_opt_help=true
                        ;;
                    "${arr_usage_opt[2]}" | "${arr_usage_opt[3]}" )
                        bool_opt_multiboot_VFIO_setup=true
                        ;;
                    "${arr_usage_opt[4]}" | "${arr_usage_opt[5]}" )
                        bool_opt_any_VFIO_setup=true
                        bool_opt_post_setup=true
                        bool_opt_pre_setup=true
                        ;;
                    "${arr_usage_opt[6]}" | "${arr_usage_opt[7]}" )
                        bool_opt_post_setup=true
                        ;;
                    "${arr_usage_opt[8]}" | "${arr_usage_opt[9]}" )
                        bool_opt_pre_setup=true
                        ;;
                    "${arr_usage_opt[10]}" | "${arr_usage_opt[11]}" )
                        bool_opt_static_VFIO_setup=true
                        ;;
                    "${arr_usage_opt[12]}" | "${arr_usage_opt[13]}" )
                        bool_opt_update_VFIO_setup=true
                        ;;
                    "${arr_usage_args[0]}" | "${arr_usage_args[1]}" )
                        bool_arg_silent=true
                        ;;
                    * )
                        bool_opt_help=true
                        echo -e "${str_output_var_is_not_valid}"
                        return 1
                        ;;
                esac
            else
                bool_opt_any_VFIO_setup=true
            fi

            case "${2}" in
                "${arr_usage_args[0]}" | "${arr_usage_args[1]}" )
                    bool_arg_silent=true
                    ;;

                "${arr_usage_args[2]}" | "${arr_usage_args[3]}" )
                    bool_arg_parse_file=true
                    ;;

                "${arr_usage_args[4]}" | "${arr_usage_args[5]}" )
                    bool_arg_parse_online=true
                    ;;
            esac
            # </params>

            return 0
        }

        # <params>
        readonly var_input1="${1}"
        readonly var_input2="${2}"
        readonly var_input3="${3}"

        declare -g bool_opt_multiboot_VFIO_setup=false
        declare -g bool_opt_any_VFIO_setup=false
        declare -g bool_opt_help=false
        declare -g bool_opt_post_setup=false
        declare -g bool_opt_pre_setup=false
        declare -g bool_opt_static_VFIO_setup=false
        declare -g bool_opt_update_VFIO_setup=false
        declare -g bool_arg_silent=false
        declare -g bool_arg_parse_file=false
        declare -g bool_arg_parse_online=false

        declare -gr str_repo_name="deploy-vfio-setup"
        declare -gr str_full_repo_name="portellam/${str_repo_name}"

        GoToScriptDir
        declare -gr str_files_dir="$( find . -name files | uniq | head -n1 | cut -c2- )/"
        declare -gr str_repos_dir="$( find . -name git | uniq | head -n1 | cut -c2- )/"

        declare -g bool_is_connected_to_Internet=false
        # </params>

        str_theFile="README.md"
        declare -a arr_theFile
        ReadFile "arr_theFile" "${str_theFile}"
        echo -e "${arr_theFile[@]}"
        exit


        # CheckIfUserIsRoot || exit "${?}"
        # GetUsage "${var_input1}" "${var_input2}"
        # SaveExitCode

        # # <remarks> Output usage </remarks>
        # if "${bool_opt_help}"; then
        #     PrintUsage
        #     exit "${int_exit_code}"
        # fi

        # # <remarks> Get and ask user to select IOMMU groups. </remarks>
        # if "${bool_opt_any_VFIO_setup}"; then
        #     case true in
        #         "${bool_arg_parse_file}" )
        #             readonly var_Parse_IOMMU="FILE"
        #             ;;

        #         "${bool_arg_parse_online}" )
        #             readonly var_Parse_IOMMU="DNS"
        #             ;;

        #         * )
        #             readonly var_Parse_IOMMU="LOCAL"
        #             ;;
        #     esac

        #     Parse_IOMMU "${var_Parse_IOMMU}" "${var_input1}" || exit "${?}"
        #     Select_IOMMU || exit "${?}"
        # fi

        # <remarks> Execute pre-setup </remarks>
        # if "${bool_opt_any_VFIO_setup}" || "${bool_opt_pre_setup}"; then
        #     AddUserToGroups
        #     Allocate_CPU
        #     Allocate_RAM
        #     Virtual_KVM
        #     Modify_QEMU
        #     RAM_Swapfile
        # fi

        # <remarks> Execute main setup </remarks>
        # if "${bool_opt_any_VFIO_setup}" && "${bool_VFIO_has_IOMMU}"; then
        #     Setup_VFIO || exit "${?}"
        # fi

        # <remarks> Execute post-setup </remarks>
        # if "${bool_opt_post_setup}"; then
        #     VirtualAudioCapture
        #     VirtualVideoCapture
        # fi
    # </code>
exit "${?}"