#!/bin/bash sh

#
# Filename:         deploy-vfio.bash
# Description:      Effortlessly deploy a VFIO setup (PCI passthrough).
# Author(s):        Alex Portell <github.com/portellam>
# Maintainer(s):    Alex Portell <github.com/portellam>
#

# <remarks> Using </remarks>
# <code>
    if ! cd bin; then
        echo -e "\033[0;31mFailure:\033[0m Could not load required libraries."
        exit 1
    fi

    source bashlib-all
    source vfiolib-all
# </code>

# <code>
function Main
{
    SetScriptDir || return $?
    IsSudoUser || return $?
    if ! SetOptions $@; then GetUsage; return $?; fi
    # if $bool_uninstall; then UninstallExisting_VFIO; fi

    # <remarks> Extras </remarks>
    AddUserToGroups
    Allocate_CPU
    Allocate_RAM
    Virtual_KVM
    Modify_QEMU
    RAM_Swapfile
    LibvirtHooks
    VirtualVideoCapture
    # VirtualAudioCapture
    GuestAudioLoopback

    exit 0

    # <remarks> Main setup </remarks>
    case true in
        $bool_parse_IOMMU_from_file )
            Parse_IOMMU "FILE" || return $?
            ;;

        $bool_parse_IOMMU_from_internet )
            Parse_IOMMU "DNS" || return $?
            ;;

        $bool_parse_IOMMU_from_local | * )
            Parse_IOMMU "LOCAL" || return $?
            ;;
    esac

    Select_IOMMU $@ || return $?

    case true in
        $bool_multiboot )
            Multiboot_VFIO
            ;;

        $bool_static )
            Static_VFIO
            ;;

        * )
            Setup_VFIO
            ;;
    esac

    return $?
}
# </code>

while [[ $? -eq 0 || $? -eq $int_code_partial_completion || $? -eq $int_code_skipped_operation ]]; do
    Main $@
    break
done

exit $?