#!/bin/bash

ce_name=$1
ip=$2
gw=$3
bridge="br_${ce_name}"
vm_tap=$4

if [ "$vm_tap" = "" ]; then
    echo "usage: $0 <ce name> <ip/mask> <gateway> <vm tap name>"
    echo
    exit
fi


ip netns add ${ce_name}
ip link add ${ce_name}_a type veth peer name ${ce_name}_b
ip link set ${ce_name}_b netns ${ce_name}    
ip netns exec ${ce_name} ip a
ip netns exec ${ce_name} ip a add ${ip} dev ${ce_name}_b 
ip netns exec ${ce_name} ip link set dev ${ce_name}_b up
ip netns exec ${ce_name} ip link set dev lo up
ip netns exec ${ce_name} ip route add default via ${gw}

brctl addbr ${bridge}
brctl addif ${bridge} ${vm_tap}
brctl addif ${bridge} ${ce_name}_a
ifconfig ${bridge} up
ip link set dev ${ce_name}_a  up

