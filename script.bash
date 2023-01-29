
# TODO
#
# -copy bash-libaries
#
#

# <summary> Validation </summary
function DetectExisting_VFIO
{}

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

# <summary> Get IOMMU </summary
function Parse_IOMMU
{
    # <summary> Return value given if a device's bus ID is Internal or External PCI. </summary>
    function IsBusInternalOrExternal
    {
        # <params>
        declare -I str_device_bus
        # </params>

        case "${str_device_bus}" in
            "00" | "01" )
                return 0
                ;;
        esac

        return 1
    }

    # <summary> Append IOMMU group *once* to another list should it meet criteria. </summary>
    function MatchDeviceType
    {
        # <params>
        declare -I arr_IOMMU_groups_with_USB arr_IOMMU_groups_with_VGA bool_is_found_IGPU_full_name str_device_type str_device_vendor str_IGPU_full_name str_IOMMU_group
        # </params>

        case "${str_device_type}" in
            "3d" | "display" | "graphics" | "vga" )
                if CheckIfVarIsValid "${arr_IOMMU_groups_with_VGA[@]}" && [[ "${str_IOMMU_group}" != "${arr_IOMMU_groups_with_VGA[-1]}" ]]; then
                    arr_IOMMU_groups_with_VGA+=( "${str_IOMMU_group}" )
                fi

                if [[ "${bool_is_found_IGPU_full_name}" == false ]]; then
                    IsBusInternalOrExternal && (
                        str_IGPU_full_name="${str_device_vendor} ${str_device_name}"
                        bool_is_found_IGPU_full_name == true
                    )
                fi

                if [[ "${bool_is_found_IGPU_full_name}" == true ]]; then
                    readonly str_IGPU_full_name
                fi
            ;;

            "usb" )
                if CheckIfVarIsValid "${arr_IOMMU_groups_with_USB[@]}" && [[ "${str_IOMMU_group}" != "${arr_IOMMU_groups_with_USB[-1]}" ]]; then
                    arr_IOMMU_groups_with_USB=( "${str_IOMMU_group}" )
                fi
            ;;
        esac

        return 0
    }

    # <summary> Get all devices within a given IOMMU group. </summary>
    function GetDevicesInGroup
    {
        # <params>
        declare -I arr_device_driver arr_device_IOMMU arr_device_name arr_device_PCI arr_device_type arr_device_vendor arr_group_devices
        declare -I arr_IOMMU_groups_with_USB arr_IOMMU_groups_with_VGA str_IGPU_full_name str_IOMMU_group
        local bool_is_found_IGPU_full_name=false
        # </params>

        for str_device in ${arr_group_devices[@]}; do
            local str_device_PCI="${str_device##"0000:"}"
            local str_device_bus=$( echo "${str_device_PCI}" | cut -d ":" -f 1 )
            declare -l str_device_driver=$( lspci -ms "${str_device}" | cut -d ':' -f2 )
            local str_device_name=$( lspci -ms "${str_device}" | cut -d '"' -f6 )
            declare -l str_device_type=$( lspci -ms "${str_device}" | cut -d '"' -f2 )
            local str_device_vendor=$( lspci -ms "${str_device}" | cut -d '"' -f4 )

            if ! CheckIfVarIsValid "${str_device_driver}" &> /dev/null || [[ "${str_device_driver}" == *"vfio-pci"* ]]; then
                str_device_driver="N/A"
            fi

            str_device_driver="${str_device_driver##" "}"
            MatchDeviceType

            if IsBusInternalOrExternal; then
                arr_IOMMU_groups_with_internal_bus+=( "${str_IOMMU_group}" )
            else
                arr_IOMMU_groups_with_external_bus+=( "${str_IOMMU_group}" )
            fi

            arr_device_driver+=( "${str_device_driver}" )
            arr_device_IOMMU+=( "${str_IOMMU_group}" )
            arr_device_name+=( "${str_device_name}" )
            arr_device_PCI+=( "${str_device_PCI}" )
            arr_device_type+=( "${str_device_type}" )
            arr_device_vendor+=( "${str_device_vendor}" )
        done

        return 0
    }

    # <summary> Get all IOMMU groups on this system. </summary>
    function GetGroups
    {
        # <params>
        declare -I arr_device_driver arr_device_IOMMU arr_device_name arr_device_PCI arr_device_type arr_device_vendor arr_group_devices arr_IOMMU_groups arr_IOMMU_groups_with_USB arr_IOMMU_groups_with_VGA str_IGPU_full_name str_IOMMU_group
        local bool_is_found_IGPU_full_name=false
        # </params>

        if ! CheckIfVarIsValid "${arr_IOMMU_groups[@]}" &> /dev/null;
            return 1
        fi

        for str_IOMMU_group in ${arr_IOMMU_groups[@]}; do
            if CheckIfVarIsValid "${str_IOMMU_group}" &> /dev/null; then
                declare -a arr_group_devices=( $( eval "${var_get_devices_of_IOMMU_group}" ) )
                GetDevicesInGroup
            fi
        done

        readonly arr_device_driver arr_device_IOMMU arr_device_name arr_device_PCI arr_device_type arr_device_vendor arr_IOMMU_groups_with_external_bus arr_IOMMU_groups_with_internal_bus arr_IOMMU_groups_with_USB arr_IOMMU_groups_with_VGA

        return 0
    }

    # <params>
    local str_output="Parsing IOMMU groups..."
    local readonly var_get_last_IOMMU_group='basename $( ls -1v /sys/kernel/iommu_groups/ | sort -hr | head -n1 )'
    local readonly var_get_devices_of_IOMMU_group='ls "${str_IOMMU_group}/devices/"'
    local readonly var_get_IOMMU_groups='find /sys/kernel/iommu_groups/* -maxdepth 0 -type d | sort -V'

    # NOTE: index 0 is empty, why?
    declare -agr arr_IOMMU_groups=( $( eval "${var_get_IOMMU_groups}" ) )
    declare -ag arr_device_driver arr_device_IOMMU arr_device_name arr_device_PCI arr_device_type arr_device_vendor arr_IOMMU_groups_with_external_bus arr_IOMMU_groups_with_internal_bus arr_IOMMU_groups_with_USB arr_IOMMU_groups_with_VGA
    declare -igr int_last_IOMMU_group=$( eval "${var_get_last_IOMMU_group}" )
    declare -g str_IGPU_full_name="N/A"
    # </params>

    echo -e "${str_output}"

    GetGroups
    AppendPassOrFail "${str_output}"
    return "${?}"
}

function ReadFromFile_IOMMU
{}

function SaveToFile_IOMMU
{}

function Select_IOMMU
{}

# <summary> Main setup </summary>
function Dynamic_VFIO
{}

function Static_VFIO
{}

function UpdateExisting_VFIO
{}

# <summary> Pre/post setup </summary
function Allocate_CPU
{}

function Allocate_RAM
{}

function LibvirtHooks
{}

function RAM_Swapfile
{}

function Virtual_KVM
{}

function VirtualVideoCapture
{}

function VirtualAudioCapture
{}

