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
    SetScriptDir || exit $?
    IsSudoUser || exit $?
    if ! SetOptions $@; then GetUsage; exit $?; fi
    # if $bool_uninstall; then UninstallExisting_VFIO fi

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

    # <remarks> Main setup </remarks>
    case true in
        $bool_parse_IOMMU_from_file )
            Parse_IOMMU "FILE" || exit $?
            ;;

        $bool_parse_IOMMU_from_internet )
            Parse_IOMMU "DNS" || exit $?
            ;;

        $bool_parse_IOMMU_from_local | * )
            Parse_IOMMU "LOCAL" || exit $?
            ;;
    esac

    Select_IOMMU $@ || exit $?

    case true in
        $bool_multiboot )
            Multiboot_VFIO
            exit $?
            ;;

        $bool_static )
            Static_VFIO
            exit $?
            ;;

        * )
            Setup_VFIO
            exit $?
            ;;
    esac
# </code>

exit 0