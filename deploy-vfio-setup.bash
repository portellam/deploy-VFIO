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

# <remarks> Using </remarks>
# <code>
    source bashlib/bin/bashlib-all
    source bin/vfiolib-all
# </code>

# <code>
    IsRootUser || exit "${?}"
    GetUsage "${var_input1}" "${var_input2}"
    SaveExitCode

    # <remarks> Output usage </remarks>
    if "${bool_opt_help}"; then
        PrintUsage
        exit "${int_exit_code}"
    fi

    # <remarks> Get and ask user to select IOMMU groups. </remarks>
    if "${bool_opt_any_VFIO_setup}"; then
        case true in
            "${bool_arg_parse_file}" )
                readonly var_Parse_IOMMU="FILE"
                ;;

            "${bool_arg_parse_online}" )
                readonly var_Parse_IOMMU="DNS"
                ;;

            * )
                readonly var_Parse_IOMMU="LOCAL"
                ;;
        esac

        Parse_IOMMU "${var_Parse_IOMMU}" "${var_input1}" || exit "${?}"
        Select_IOMMU || exit "${?}"
    fi

    # <remarks> Execute pre-setup </remarks>
    if "${bool_opt_any_VFIO_setup}" || "${bool_opt_pre_setup}"; then
        AddUserToGroups
        Allocate_CPU
        Allocate_RAM
        Virtual_KVM
        Modify_QEMU
        RAM_Swapfile
    fi

    # <remarks> Execute main setup </remarks>
    if "${bool_opt_any_VFIO_setup}" && "${bool_VFIO_has_IOMMU}"; then
        Setup_VFIO || exit "${?}"
    fi

    # <remarks> Execute post-setup </remarks>
    if "${bool_opt_post_setup}"; then
        VirtualAudioCapture
        VirtualVideoCapture
    fi
# </code>

exit "${?}"