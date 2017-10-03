#!/bin/bash

VMID=""
VMTYPE=""

while [[ $# > 0 ]]; do
    key="$1"
    case $key in
        --type)
        VMTYPE="$2"
        shift # past argument
        ;;
        --id)
        VMID="$2"
        shift # past argument
        ;;
        *)
                # unknown option
        ;;
    esac
    shift # past argument or value
done


if [ "X$VMTYPE" == "X" ]; then
    echo "usage: $0 --id <vm id 10-99> \
        --type <vmx|n9kv>  "
fi




del_tap_n9kv () {
    tunctl -d tap${VMID}00
    tunctl -d tap${VMID}01
    tunctl -d tap${VMID}02
    tunctl -d tap${VMID}03
    tunctl -d tap${VMID}04
    tunctl -d tap${VMID}05
    tunctl -d tap${VMID}06
    tunctl -d tap${VMID}07
    tunctl -d tap${VMID}08
    tunctl -d tap${VMID}09
    tunctl -d tap${VMID}10
}
   




kill_n9kv () {
    pid=`ps -ef | grep "n9kv-${VMID}" | grep qemu | grep -v grep | awk '{print $2}'`
    kill -9 $pid
}




del_tap_vmx() {
    tunctl -d tap${VMID}00
    tunctl -d tap${VMID}01
    tunctl -d tap${VMID}30
    tunctl -d tap${VMID}31

    tunctl -d tap${VMID}10
    tunctl -d tap${VMID}11
    tunctl -d tap${VMID}12
    tunctl -d tap${VMID}13
    tunctl -d tap${VMID}14
    tunctl -d tap${VMID}15
    tunctl -d tap${VMID}16
    tunctl -d tap${VMID}17
    tunctl -d tap${VMID}18
    tunctl -d tap${VMID}19
    tunctl -d tap${VMID}20
    tunctl -d tap${VMID}21
    tunctl -d tap${VMID}22
    tunctl -d tap${VMID}23
    tunctl -d tap${VMID}24
    tunctl -d tap${VMID}25
    tunctl -d tap${VMID}26
    tunctl -d tap${VMID}27
    tunctl -d tap${VMID}28
    tunctl -d tap${VMID}29


    #RE-to-FPC
    ifconfig vmx${VMID}01_re down
    brctl delbr vmx${VMID}01_re
}




kill_vmx() {
    pid=`ps -ef | grep "vmx-${VMID}-re" | grep qemu | grep -v grep | awk '{print $2}'`
    kill -9 $pid
    
    pid=`ps -ef | grep "vmx-${VMID}-fpc" | grep qemu | grep -v grep | awk '{print $2}'`
    kill -9 $pid
}




# main

if [ "$VMTYPE" == "n9kv" ]; then
    kill_n9kv
    sleep 2
    del_tap_n9kv
elif [ "$VMTYPE" == "vmx" ]; then
    kill_vmx
    sleep 2
    del_tap_vmx
else
    echo "VM type $TYPE is not supported"
fi


