#!/usr/bin/env bash

exit 0

# todo: debug

#
# Original author(s):   Rokas Kupstys <rokups@zoho.com>
#                       Danny Lin <danny@kdrag0n.dev>
# Current author(s):    Alex Portell <github.com/portellam>
#
# This hook uses the `cset` tool to dynamically isolate and unisolate CPUs using
# the kernel's cgroup cpusets feature. While it's not as effective as
# full kernel-level scheduler and timekeeping isolation, it still does wonders
# for VM latency as compared to not isolating CPUs at all. Note that vCPU thread
# affinity is a must for this to work properly.
#
# Original source(s):   https://rokups.github.io/#!pages/gaming-vm-performance.md
#                       https://github.com/PassthroughPOST/VFIO-Tools/blob/master/libvirt_hooks/hooks/cset.sh
#
# Target file locations:
#   - $SYSCONFDIR/hooks/qemu.d/vm_name/prepare/begin/cset.sh
#   - $SYSCONFDIR/hooks/qemu.d/vm_name/release/end/cset.sh
# $SYSCONFDIR is usually /etc/libvirt.
#

# parameters #
str_domain_name="$1"
str_domain_action="$2/$3"
readonly declare -i int_total_cores=`cat /proc/cpuinfo | grep 'cpu cores' | uniq`
readonly declare -i int_total_threads=`cat /proc/cpuinfo | grep 'processor'`
readonly declare -i int_multi_thread=$(( $int_total_threads / $int_total_cores ))
readonly declare -i int_last_thread=$(( $int_total_threads - 1 ))
readonly str_total_threads="0-$int_last_thread"
declare -i int_host_cores=1     # default value

## reserve remainder cores to host ##
# >= 4-core CPU, leave max 2
if [[ $int_total_cores -ge 4 ]]; then
    int_host_cores=2

# 2 or 3-core CPU, leave max 1
elif [[ $int_total_cores -le 3 && $int_total_cores -ge 2 ]]; then
    int_host_cores=1

# 1-core CPU, do not reserve cores to virt
else
    int_host_cores=$int_total_cores
fi

# parse total cores #
for (( int_i=0 ; int_i<$int_total_cores ; int_i++ )); do

    # reserve cores to host #
    if [[ $int_i -lt $int_host_cores ]]; then
        arr_host_cores+=( $int_i )
        #
        # host 0,1
        #

    # reserve cores to virt #
    else
        arr_virt_cores+=( $int_i )
        #
        # virt 2,3,4,5,6,7
        #
    fi
done

## save output to string for cpuset and cpumask #
# parse multi thread #
declare -i int_i=1
while [[ $int_i -le $int_multi_thread ]]; do
    
    # parse host cores #
    for (( int_j=0 ; int_j<${arr_host_cores[@]} ; int_j++ )); do
        declare -i int_k=$(( int_j++ ))

        # update array of host threads, for cpumask #
        arr_host_threads+=( $(( ${arr_host_cores[$int_j]} * $int_multi_thread )) )

        # match next valid element, and diff is equal to 1, update temp array, for cpuset #
        if [[ ! -z ${arr_host_cores[$int_k]} && $(( ${arr_host_cores[$int_k]} - ${arr_host_cores[$int_j]} )) -eq 1 ]]; then
            declare -a arr_temp1=( ${arr_host_cores[0]}, ${arr_host_cores[$int_k]} )
        fi
    done

    # parse host cores #
    for (( int_j=0 ; int_j<${arr_virt_cores[@]} ; int_j++ )); do
        declare -i int_k=$(( int_j++ ))

        # match next valid element, and diff is equal to 1, update temp array
        if [[ ! -z ${arr_virt_cores[$int_k]} && $(( ${arr_virt_cores[$int_k]} - ${arr_virt_cores[$int_j]} )) -eq 1 ]]; then
            declare -a arr_temp2=( ${arr_virt_cores[0]}, ${arr_virt_cores[$int_k]} )
        fi
    done

    # format and update list of host threads #
    str_host_threads+=$(( ${arr_temp1[0]} * $int_i ))"-"$(( ${arr_temp1[1]} * $int_i ))","
    str_virt_threads+=$(( ${arr_temp2[0]} * $int_i ))"-"$(( ${arr_temp2[1]} * $int_i ))","
    ((int_i++))
done

# remove last separator #
if [[ ${str_host_threads: -1} == "," ]]; then
    str_host_threads=${str_host_threads::-1}
fi

if [[ ${str_virt_threads: -1} == "," ]]; then
    str_virt_threads=${str_virt_threads::-1}
fi

# find cpu mask #
readonly declare -i int_total_threads_mask=$(( ( 2 ** $int_total_threads ) - 1 ))

declare -i int_host_threads_mask=0
for int_thread in ${arr_host_threads[@]}; do
    int_host_threads_mask+=$(( 2 ** $int_thread ))
done

# int to hex #
readonly hex_total_threads_mask=`printf '%x\n' $int_total_threads_mask`
readonly hex_host_threads_mask=`printf '%x\n' $int_host_threads_mask`

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

function shield_vm() {
    cset -m set -c $str_total_threads -s machine.slice
    cset -m shield --kthread on --cpu $str_virt_threads
}

function unshield_vm() {
    cset -m shield --reset
}

# For convenient manual invocation #
if [[ "$str_domain_name" == "shield" ]]; then
    shield_vm
    exit
elif [[ "$str_domain_name" == "unshield" ]]; then
    unshield_vm
    exit
fi

if [[ "$str_domain_action" == "prepare/begin" ]]; then
    echo "libvirt-qemu cset: Reserving CPUs $str_virt_threads for VM $str_domain_name" > /dev/kmsg 2>&1
    shield_vm > /dev/kmsg 2>&1

    # the kernel's dirty page writeback mechanism uses kthread workers. They introduce
    # massive arbitrary latencies when doing disk writes on the host and aren't
    # migrated by cset. Restrict the workqueue to use only cpu 0.
    echo $hex_host_threads_mask > /sys/bus/workqueue/devices/writeback/cpumask
    echo 0 > /sys/bus/workqueue/devices/writeback/numa

    echo "libvirt-qemu cset: Successfully reserved CPUs $str_virt_threads" > /dev/kmsg 2>&1
elif [[ "$str_domain_action" == "release/end" ]]; then
    echo "libvirt-qemu cset: Releasing CPUs $str_virt_threads from VM $str_domain_name" > /dev/kmsg 2>&1
    unshield_vm > /dev/kmsg 2>&1

    # Revert changes made to the writeback workqueue
    echo $hex_total_threads_mask > /sys/bus/workqueue/devices/writeback/cpumask
    echo 1 > /sys/bus/workqueue/devices/writeback/numa

    echo "libvirt-qemu cset: Successfully released CPUs $str_virt_threads" > /dev/kmsg 2>&1
fi