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
    IsSudoUser || exit $?
    if ! SetOptions $@; then GetUsage; exit $?; fi
    if $bool_uninstall; then UninstallExisting_VFIO fi

    # <remarks> Extras </remarks>
    AddUserToGroups
    if $bool_alloc_cpu; then Allocate_CPU; fi
    if $bool_hugepages; then Allocate_RAM; fi
    if $bool_evdev; then Virtual_KVM; fi
    Modify_QEMU
    if $bool_zram_swap; then RAM_Swapfile; fi
    if $bool_libvirt_hooks; then LibvirtHooks; fi
    if $bool_looking_glass; then VirtualVideoCapture; fi
    # if $bool_scream; then VirtualAudioCapture; fi
    if $bool_audio_loopback; then GuestAudioLoopback; fi

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