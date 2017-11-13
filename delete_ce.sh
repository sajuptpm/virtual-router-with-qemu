#!/bin/bash

ce_name=$1
bridge="br_${ce_name}"
vm_tap=$2

if [ "$vm_tap" = "" ]; then
    echo "usage: $0 <ce name> <vm tap name>"
    echo
    exit
fi


ip netns del ${ce_name}
brctl delif ${bridge} ${vm_tap}
brctl delif ${bridge} ${ce_name}_a
ip link delete ${ce_name}_a
ifconfig ${bridge} down
brctl delbr ${bridge}

