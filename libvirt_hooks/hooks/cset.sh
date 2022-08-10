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
str_domainName="$1"
str_domainAction="$2/$3"
readonly declare -i int_totalCores=`cat /proc/cpuinfo | grep 'cpu cores' | uniq`
readonly declare -i int_totalThreads=`cat /proc/cpuinfo | grep 'processor'`
readonly declare -i int_multiThread=$(( $int_totalThreads / $int_totalCores ))
readonly declare -i int_lastThread=$(( $int_totalThreads - 1 ))
readonly str_totalThreads="0-$int_lastThread"
declare -i int_hostCores=1     # default value

## reserve remainder cores to host ##
# >= 4-core CPU, leave max 2
if [[ $int_totalCores -ge 4 ]]; then
    int_hostCores=2

# 2 or 3-core CPU, leave max 1
elif [[ $int_totalCores -le 3 && $int_totalCores -ge 2 ]]; then
    int_hostCores=1

# 1-core CPU, do not reserve cores to virt
else
    int_hostCores=$int_totalCores
fi

# parse total cores #
for (( int_i=0 ; int_i<$int_totalCores ; int_i++ )); do

    # reserve cores to host #
    if [[ $int_i -lt $int_hostCores ]]; then
        arr_hostCores+=( $int_i )
        #
        # host 0,1
        #

    # reserve cores to virt #
    else
        arr_virtCores+=( $int_i )
        #
        # virt 2,3,4,5,6,7
        #
    fi
done

## save output to string for cpuset and cpumask #
# parse multi thread #
declare -i int_i=1
while [[ $int_i -le $int_multiThread ]]; do
    
    # parse host cores #
    for (( int_j=0 ; int_j<${arr_hostCores[@]} ; int_j++ )); do
        declare -i int_k=$(( int_j++ ))

        # update array of host threads, for cpumask #
        arr_hostThreads+=( $(( ${arr_hostCores[$int_j]} * $int_multiThread )) )

        # match next valid element, and diff is equal to 1, update temp array, for cpuset #
        if [[ ! -z ${arr_hostCores[$int_k]} && $(( ${arr_hostCores[$int_k]} - ${arr_hostCores[$int_j]} )) -eq 1 ]]; then
            declare -a arr_temp1=( ${arr_hostCores[0]}, ${arr_hostCores[$int_k]} )
        fi
    done

    # parse host cores #
    for (( int_j=0 ; int_j<${arr_virtCores[@]} ; int_j++ )); do
        declare -i int_k=$(( int_j++ ))

        # match next valid element, and diff is equal to 1, update temp array
        if [[ ! -z ${arr_virtCores[$int_k]} && $(( ${arr_virtCores[$int_k]} - ${arr_virtCores[$int_j]} )) -eq 1 ]]; then
            declare -a arr_temp2=( ${arr_virtCores[0]}, ${arr_virtCores[$int_k]} )
        fi
    done

    # format and update list of host threads #
    str_hostThreads+=$(( ${arr_temp1[0]} * $int_i ))"-"$(( ${arr_temp1[1]} * $int_i ))","
    str_virtThreads+=$(( ${arr_temp2[0]} * $int_i ))"-"$(( ${arr_temp2[1]} * $int_i ))","
    ((int_i++))
done

# remove last separator #
if [[ ${str_hostThreads: -1} == "," ]]; then
    str_hostThreads=${str_hostThreads::-1}
fi

if [[ ${str_virtThreads: -1} == "," ]]; then
    str_virtThreads=${str_virtThreads::-1}
fi

# find cpu mask #
readonly declare -i int_totalThreads_mask=$(( ( 2 ** $int_totalThreads ) - 1 ))

declare -i int_hostThreads_mask=0
for int_element in ${arr_hostThreads[@]}; do
    int_hostThreads_mask+=$(( 2 ** $int_element ))
done

# int to hex #
readonly hex_totalThreads_mask=`printf '%x\n' $int_totalThreads_mask`
readonly hex_hostThreads_mask=`printf '%x\n' $int_hostThreads_mask`

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

# functions #
function shield_vm() {
    cset -m set -c $str_totalThreads -s machine.slice
    cset -m shield --kthread on --cpu $str_virtThreads
}

function unshield_vm() {
    cset -m shield --reset
}

# For convenient manual invocation #
if [[ "$str_domainName" == "shield" ]]; then
    shield_vm
    exit
elif [[ "$str_domainName" == "unshield" ]]; then
    unshield_vm
    exit
fi

if [[ "$str_domainAction" == "prepare/begin" ]]; then
    echo "libvirt-qemu cset: Reserving CPUs $str_virtThreads for VM $str_domainName" > /dev/kmsg 2>&1
    shield_vm > /dev/kmsg 2>&1

    # the kernel's dirty page writeback mechanism uses kthread workers. They introduce
    # massive arbitrary latencies when doing disk writes on the host and aren't
    # migrated by cset. Restrict the workqueue to use only cpu 0.
    echo $hex_hostThreads_mask > /sys/bus/workqueue/devices/writeback/cpumask
    echo 0 > /sys/bus/workqueue/devices/writeback/numa

    echo "libvirt-qemu cset: Successfully reserved CPUs $str_virtThreads" > /dev/kmsg 2>&1
elif [[ "$str_domainAction" == "release/end" ]]; then
    echo "libvirt-qemu cset: Releasing CPUs $str_virtThreads from VM $str_domainName" > /dev/kmsg 2>&1
    unshield_vm > /dev/kmsg 2>&1

    # Revert changes made to the writeback workqueue
    echo $hex_totalThreads_mask > /sys/bus/workqueue/devices/writeback/cpumask
    echo 1 > /sys/bus/workqueue/devices/writeback/numa

    echo "libvirt-qemu cset: Successfully released CPUs $str_virtThreads" > /dev/kmsg 2>&1
fi