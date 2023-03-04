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
    bool_full_setup=false
    IsSudoUser || exit $?
    if ! SetOptions $@; then GetUsage; exit $?; fi
    if ! IsString $1; bool_full_setup=true
    if ! $bool_full_setup && $bool_uninstall; then UninstallExisting_VFIO fi

    # <remarks> Extras </remarks>
    AddUserToGroups
    if $bool_full_setup || $bool_alloc_cpu; then Allocate_CPU; fi
    if $bool_full_setup || $bool_hugepages; then Allocate_RAM; fi
    if $bool_full_setup || $bool_evdev; then Virtual_KVM; fi
    Modify_QEMU
    if $bool_full_setup || $bool_zram_swap; then RAM_Swapfile; fi
    if $bool_full_setup || $bool_libvirt_hooks; then LibvirtHooks; fi
    if $bool_full_setup || $bool_looking_glass; then VirtualVideoCapture; fi
    # if $bool_full_setup || $bool_scream; then VirtualAudioCapture; fi
    if $bool_full_setup || $bool_audio_loopback; then GuestAudioLoopback; fi

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

    if $bool_multiboot; then
        Multiboot_VFIO || exit $?
    elif $bool_static; then
        Static_VFIO || exit $?
    else
        Setup_VFI0 || exit $?
    fi
# </code>

exit 0