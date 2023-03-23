#!/bin/bash sh

#
# Filename:         deploy-vfio.bash
# Description:      Effortlessly deploy a VFIO setup (PCI passthrough).
# Author(s):        Alex Portell <github.com/portellam>
# Maintainer(s):    Alex Portell <github.com/portellam>
#

# <remarks> Using </remarks>
# <code>
    cd bin
    source bashlib-all
    source vfiolib-all
# </code>

# <code>
function Main
{
    SetScriptDir || return $?
    IsSudoUser || return $?
    if ! SetOptions $@; then GetUsage; return $?; fi
    # if $bool_uninstall; then UninstallExisting_VFIO fi

    # <remarks> Extras </remarks>
    AddUserToGroups
    Allocate_CPU
    Allocate_RAM
    Virtual_KVM
    RAM_Swapfile
    LibvirtHooks
    # GuestVideoCapture     # currently failing.
    GuestAudioLoopback
    # GuestAudioStream      # currently failing.
    Modify_QEMU

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
    local str_output="Installing VFIO setup..."

    # TODO: pci ids, and other info are not being written to files. Need to fix setup!

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

    PrintPassOrFail "${str_output}"
    return $?
}
# </code>

while [[ $? -eq 0 || $? -eq $int_code_partial_completion || $? -eq $int_code_skipped_operation ]]; do
    Main $@
    break
done

exit $?