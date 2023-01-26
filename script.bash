


function IsEnabledIOMMU
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

function ParseIOMMU
{
    # <params>
    local readonly str_output="Parsing IOMMU groups..."
    local readonly var_get_last_IOMMU_group='basename $( ls -1v /sys/kernel/iommu_groups/ | sort -hr | head -n1 )'
    local readonly var_get_devices_of_IOMMU_group='ls "${str_IOMMU_group}/devices/"'
    local readonly var_get_IOMMU_groups='find /sys/kernel/iommu_groups/* -maxdepth 0 -type d | sort -V'

    # NOTE: index 0 is empty, why?
    declare -ar arr_IOMMU_groups=( $( eval "${var_get_IOMMU_groups}" ) )
    declare -ir int_last_IOMMU_group=$( eval "${var_get_last_IOMMU_group}" )

    # </params>

    CheckIfVarIsValid "${arr_IOMMU_groups[@]}"

    for str_IOMMU_group in ${arr_IOMMU_groups[@]}; do
        if CheckIfVarIsValid "${str_IOMMU_group}" &> /dev/null; then
            declare -a arr_group_devices=( $( eval "${var_get_device_from_IOMMU_group}" ) )

            for str_device in ${arr_group_devices[@]}; do
                local str_device_PCI="${str_device##"0000:"}"
                local str_device_bus=$( echo "${str_device_PCI}" | cut -d ":" -f 1 )
                declare -l str_device_driver=$( lspci -ms "${str_device}" | cut -d ':' -f2 )
                local str_device_name=$( lspci -ms "${str_device}" | cut -d '"' -f6 )
                local str_device_type=$( lspci -ms "${str_device}" | cut -d '"' -f2 )
                local str_device_vendor=$( lspci -ms "${str_device}" | cut -d '"' -f4 )

                if ! CheckIfVarIsValid "${str_device_driver}" &> /dev/null || [[ "${str_device_driver}" == *"vfio-pci"* ]]; then
                    str_device_driver="N/A"
                fi

                str_device_driver="${str_device_driver##" "}"

                
            done
        fi
    done

}