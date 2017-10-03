#!/bin/bash

MASTER_IMG_N9KV="/data/kvm/nxosv/nxosv-final.7.0.3.I7.1.qcow2"
MASTER_IMG_VMX_RE="/data/kvm/vmx/junos-vmx-x86-64-17.2-20170519.0.qcow2"
MASTER_IMG_VMX_FPC="/data/kvm/vmx/fpc-17.1.img"

RUN_FOLDER="/data/kvm/run"

VMID="1"
IP="192.168.1.199"
GW="192.168.1.1"
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
        --ip)
        IP="$2"
        shift # past argument
        ;;
        --netmask)
        NETMASK="$2"
        shift # past argument
        ;;
        --gw)
        GW="$2"
        shift # past argument
        ;;
        --bridge)
        MGMT_BRIDGE="$2"
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
        --ip <vm mgmt ip> \
        --gw <vm default gw> \ 
        --type <vmx|n9kv>  \
        --bridge <bridge for management access>"
fi


enable_kvm () {
    modprobe tun 2> /dev/null
    modprobe kvm 2> /dev/null
    modprobe kvm-intel 2> /dev/null
    modprobe kvm-amd 2> /dev/null
}



init_tap_n9kv () {
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

    tunctl -t tap${VMID}00
    tunctl -t tap${VMID}01
    tunctl -t tap${VMID}02
    tunctl -t tap${VMID}03
    tunctl -t tap${VMID}04
    tunctl -t tap${VMID}05
    tunctl -t tap${VMID}06
    tunctl -t tap${VMID}07
    tunctl -t tap${VMID}08
    tunctl -t tap${VMID}10

    ifconfig tap${VMID}00 up
    ifconfig tap${VMID}01 up
    ifconfig tap${VMID}02 up
    ifconfig tap${VMID}03 up
    ifconfig tap${VMID}04 up
    ifconfig tap${VMID}05 up
    ifconfig tap${VMID}06 up
    ifconfig tap${VMID}07 up
    ifconfig tap${VMID}08 up
    ifconfig tap${VMID}09 up
    ifconfig tap${VMID}10 up

    intf_00="52:53:01:00:${VMID}:00"
    intf_01="52:53:01:00:${VMID}:01"
    intf_02="52:53:01:00:${VMID}:02"
    intf_03="52:53:01:00:${VMID}:03"
    intf_04="52:53:01:00:${VMID}:04"
    intf_05="52:53:01:00:${VMID}:05"
    intf_06="52:53:01:00:${VMID}:06"
    intf_07="52:53:01:00:${VMID}:07"
    intf_08="52:53:01:00:${VMID}:08"
    intf_09="52:53:01:00:${VMID}:09"
    intf_10="52:53:01:00:${VMID}:10"

    #add to bridge
    brctl addif ${MGMT_BRIDGE} tap${VMID}00
}
   


prepare_n9kv () {
    cp ${MASTER_IMG_N9KV} ${RUN_FOLDER}/n9kv-${VMID}.qcow2
    if [ -d  template/n9kv-${VMID} ]; then
        rm -rf  template/n9kv-${VMID}
    fi
    cp -a template/n9kv template/n9kv-${VMID}
    sed -i "s/MGMT_IP/${IP}/g" template/n9kv-${VMID}/NXOS_CONFIG.TXT
    sed -i "s/NETMASK/${NETMASK}/g" template/n9kv-${VMID}/NXOS_CONFIG.TXT
    sed -i "s/GATEWAY/${GW}/g" template/n9kv-${VMID}/NXOS_CONFIG.TXT
    mkisofs -l -o  ${RUN_FOLDER}/n9kv-${VMID}-config.iso template/n9kv-${VMID}/
}


launch_n9kv () {
    prepare_n9kv
    sleep 2
    qemu-system-x86_64 -enable-kvm -hda ${RUN_FOLDER}/n9kv-${VMID}.qcow2 \
        -cdrom ${RUN_FOLDER}/n9kv-${VMID}-config.iso \
        -daemonize \
        -vnc 0.0.0.0:1${VMID} -device cirrus-vga,id=video0,bus=pci.0,addr=0x2 \
        -bios /usr/share/ovmf/OVMF.fd \
        -serial telnet:0.0.0.0:410${VMID},nowait,server \
        -monitor tcp:0.0.0.0:420${VMID},server,nowait,nodelay \
        -m 8192M -smp 2 \
        -netdev tap,id=t${VMID}00,ifname=tap${VMID}00,script=no,downscript=no -device e1000,mac=${intf_00},netdev=t${VMID}00,addr=4.0,multifunction=on,id=nic00 \
        -netdev tap,id=t${VMID}01,ifname=tap${VMID}01,script=no,downscript=no -device e1000,mac=${intf_01},netdev=t${VMID}01,addr=4.1,multifunction=on,id=nic01 \
        -netdev tap,id=t${VMID}02,ifname=tap${VMID}02,script=no,downscript=no -device e1000,mac=${intf_02},netdev=t${VMID}02,addr=4.2,multifunction=on,id=nic02 \
        -netdev tap,id=t${VMID}03,ifname=tap${VMID}03,script=no,downscript=no -device e1000,mac=${intf_03},netdev=t${VMID}03,addr=5.0,multifunction=on,id=nic03 \
        -netdev tap,id=t${VMID}04,ifname=tap${VMID}04,script=no,downscript=no -device e1000,mac=${intf_04},netdev=t${VMID}04,addr=5.1,multifunction=on,id=nic04 \
        -netdev tap,id=t${VMID}05,ifname=tap${VMID}05,script=no,downscript=no -device e1000,mac=${intf_05},netdev=t${VMID}05,addr=5.2,multifunction=on,id=nic05 \
        -netdev tap,id=t${VMID}06,ifname=tap${VMID}06,script=no,downscript=no -device e1000,mac=${intf_06},netdev=t${VMID}06,addr=5.3,multifunction=on,id=nic06 \
        -netdev tap,id=t${VMID}07,ifname=tap${VMID}07,script=no,downscript=no -device e1000,mac=${intf_07},netdev=t${VMID}07,addr=6.0,multifunction=on,id=nic07 \
        -netdev tap,id=t${VMID}08,ifname=tap${VMID}08,script=no,downscript=no -device e1000,mac=${intf_08},netdev=t${VMID}08,addr=6.1,multifunction=on,id=nic08 \
        -netdev tap,id=t${VMID}09,ifname=tap${VMID}09,script=no,downscript=no -device e1000,mac=${intf_09},netdev=t${VMID}09,addr=6.2,multifunction=on,id=nic09 \
        -netdev tap,id=t${VMID}10,ifname=tap${VMID}10,script=no,downscript=no -device e1000,mac=${intf_10},netdev=t${VMID}10,addr=6.3,multifunction=on,id=nic10 

}




init_tap_vmx() {
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


    tunctl -t tap${VMID}00
    tunctl -t tap${VMID}01
    tunctl -t tap${VMID}30
    tunctl -t tap${VMID}31

    tunctl -t tap${VMID}10
    tunctl -t tap${VMID}11
    tunctl -t tap${VMID}12
    tunctl -t tap${VMID}13
    tunctl -t tap${VMID}14
    tunctl -t tap${VMID}15
    tunctl -t tap${VMID}16
    tunctl -t tap${VMID}17
    tunctl -t tap${VMID}18
    tunctl -t tap${VMID}19
    tunctl -t tap${VMID}20
    tunctl -t tap${VMID}21
    tunctl -t tap${VMID}22
    tunctl -t tap${VMID}23
    tunctl -t tap${VMID}24
    tunctl -t tap${VMID}25
    tunctl -t tap${VMID}26
    tunctl -t tap${VMID}27
    tunctl -t tap${VMID}28
    tunctl -t tap${VMID}29


    ifconfig tap${VMID}00 up
    ifconfig tap${VMID}01 up
    ifconfig tap${VMID}02 up
    ifconfig tap${VMID}30 up
    ifconfig tap${VMID}31 up

    ifconfig tap${VMID}10 up
    ifconfig tap${VMID}11 up
    ifconfig tap${VMID}12 up
    ifconfig tap${VMID}13 up
    ifconfig tap${VMID}14 up
    ifconfig tap${VMID}15 up
    ifconfig tap${VMID}16 up
    ifconfig tap${VMID}17 up
    ifconfig tap${VMID}18 up
    ifconfig tap${VMID}19 up
    ifconfig tap${VMID}20 up
    ifconfig tap${VMID}21 up
    ifconfig tap${VMID}22 up
    ifconfig tap${VMID}23 up
    ifconfig tap${VMID}24 up
    ifconfig tap${VMID}25 up
    ifconfig tap${VMID}26 up
    ifconfig tap${VMID}27 up
    ifconfig tap${VMID}28 up
    ifconfig tap${VMID}29 up

    vmx_re_a="52:52:00:00:${VMID}:00"
    vmx_re_b="52:52:00:00:${VMID}:01"
    vmx_fpc_a="52:52:01:00:${VMID}:00"
    vmx_fpc_b="52:52:01:00:${VMID}:01"

    vmx_fpc_0="52:53:01:00:${VMID}:00"
    vmx_fpc_1="52:53:01:00:${VMID}:01"
    vmx_fpc_2="52:53:01:00:${VMID}:02"
    vmx_fpc_3="52:53:01:00:${VMID}:03"
    vmx_fpc_4="52:53:01:00:${VMID}:04"
    vmx_fpc_5="52:53:01:00:${VMID}:05"
    vmx_fpc_6="52:53:01:00:${VMID}:06"
    vmx_fpc_7="52:53:01:00:${VMID}:07"
    vmx_fpc_8="52:53:01:00:${VMID}:08"
    vmx_fpc_9="52:53:01:00:${VMID}:09"
    vmx_fpc_10="52:53:01:00:${VMID}:10"
    vmx_fpc_11="52:53:01:00:${VMID}:11"
    vmx_fpc_12="52:53:01:00:${VMID}:12"
    vmx_fpc_13="52:53:01:00:${VMID}:13"
    vmx_fpc_14="52:53:01:00:${VMID}:14"
    vmx_fpc_15="52:53:01:00:${VMID}:15"
    vmx_fpc_16="52:53:01:00:${VMID}:16"
    vmx_fpc_17="52:53:01:00:${VMID}:17"
    vmx_fpc_18="52:53:01:00:${VMID}:18"
    vmx_fpc_19="52:53:01:00:${VMID}:19"

    #RE-to-FPC
    brctl addbr vmx${VMID}01_re
    ifconfig vmx${VMID}01_re up
    brctl addif vmx${VMID}01_re tap${VMID}01
    brctl addif vmx${VMID}01_re tap${VMID}31

    #add to external  bridge
    brctl addif ${MGMT_BRIDGE} tap${VMID}00
    brctl addif ${MGMT_BRIDGE} tap${VMID}30
    
    ##FPC-to-FPC (N/A in official vMX)
    #brctl addbr vmx${VMID}01_fpc
    #ifconfig vmx${VMID}01_fpc up
    #brctl addif vmx${VMID}01_fpc tap${VMID}02
    #brctl addif vmx${VMID}01_fpc tap${VMID}32
}




prepare_vmx () {
    cp ${MASTER_IMG_VMX_RE} ${RUN_FOLDER}/vmx-${VMID}-re.qcow2
    cp ${MASTER_IMG_VMX_FPC} ${RUN_FOLDER}/vmx-${VMID}-fpc.img
    mkdir -p /mnt/vmx-${VMID}
  
    if [ -d template/vmx/meta_data.${VMID} ]; then
        rm -rf template/vmx/meta_data.${VMID}
    fi
    cp -a ./template/vmx/meta_data ./template/vmx/meta_data.${VMID} 
    for ts in latest 2012-08-10 2013-04-04 2013-10-17 2015-10-15; do
        sed -i "s/GATEWAY/${GW}/g"      .//template/vmx/meta_data.${VMID}/${ts}/meta_data.json
        sed -i "s/MGMT_IP/${IP}/g"      .//template/vmx/meta_data.${VMID}/${ts}/meta_data.json
        sed -i "s/NETMASK/${NETMASK}/g" .//template/vmx/meta_data.${VMID}/${ts}/meta_data.json
    done
    cp template/image/vmx.config.img.master template/image/vmx.config.img.${VMID}
    mount -o loop template/image/vmx.config.img.${VMID} /mnt/vmx-${VMID}
    cp .//template/vmx/meta_data.${VMID}/latest/meta_data.json /mnt/vmx-${VMID}/openstack/latest/meta_data.json
    cp .//template/vmx/meta_data.${VMID}/2015-10-15/meta_data.json /mnt/vmx-${VMID}/openstack/2015-10-15/meta_data.json
    cp .//template/vmx/meta_data.${VMID}/2013-10-17/meta_data.json /mnt/vmx-${VMID}/openstack/2013-10-17/meta_data.json
    cp .//template/vmx/meta_data.${VMID}/2013-04-04/meta_data.json /mnt/vmx-${VMID}/openstack/2013-04-04/meta_data.json
    cp .//template/vmx/meta_data.${VMID}/2012-08-10/meta_data.json /mnt/vmx-${VMID}/openstack/2012-08-10/meta_data.json
    umount  /mnt/vmx-${VMID}
    mv template/image/vmx.config.img.${VMID} ${RUN_FOLDER}/vmx-${VMID}-re-config.img
    #cp template/disk.config ${RUN_FOLDER}/vmx-${VMID}-re-config.img

    rmdir /mnt/vmx-${VMID}
}


        #-smbios type=1,manufacturer=OpenStack Foundation,product="OpenStack Nova",version=13.0.0,serial=49434d53-0200-9037-2500-3790250074fa,uuid=83a66210-c446-4ff1-8fce-91f57f3c48f1,family="Virtual Machine" \
        #-smbios type=1,manufacturer="OpenStack Foundation",product=OpenStack Nova,version=13.0.0,serial=49434d53-0200-9037-2500-3790250074fa,uuid=ba03618d-ab6e-4296-9dfa-2c8977e2cfbb,family="Virtual Machine" \

launch_vmx() {
    prepare_vmx
    sleep 2
    qemu-system-x86_64 -snapshot -enable-kvm -hda ${RUN_FOLDER}/vmx-${VMID}-re.qcow2 \
        -hdb ${RUN_FOLDER}/vmx-${VMID}-re-config.img \
        -machine pc-i440fx-xenial,accel=kvm,usb=off \
        -cpu Nehalem,+rdtscp,+pdpe1gb,+dca,+pcid,+pdcm,+xtpr,+tm2,+est,+smx,+vmx,+ds_cpl,+monitor,+dtes64,+pbe,+tm,+ht,+ss,+acpi,+ds,+vme \
        -daemonize \
        -rtc base=utc,driftfix=slew -global kvm-pit.lost_tick_policy=discard -no-hpet \
        -realtime mlock=off \
        -vnc 0.0.0.0:1${VMID} -device cirrus-vga,id=video0,bus=pci.0,addr=0x2 \
        -serial telnet:0.0.0.0:410${VMID},nowait,server \
        -monitor tcp:0.0.0.0:411${VMID},server,nowait,nodelay \
        -m 4096M -smp 1 \
        -netdev tap,id=t${VMID}00,ifname=tap${VMID}00,script=no,downscript=no -device virtio-net-pci,mac=${vmx_re_a},netdev=t${VMID}00,addr=3.0,multifunction=on,id=nic00 \
        -netdev tap,id=t${VMID}01,ifname=tap${VMID}01,script=no,downscript=no -device virtio-net-pci,mac=${vmx_re_b},netdev=t${VMID}01,addr=3.1,multifunction=on,id=nic01 \
        #-L /opt/northstar/thirdparty/qemu/share/qemu \
        #-smbios type=1,product=VM-vmx10${VMID}-re-0
    


    qemu-system-x86_64 -snapshot -enable-kvm -hda ${RUN_FOLDER}/vmx-${VMID}-fpc.img \
        -daemonize \
        -machine pc-i440fx-xenial,accel=kvm,usb=off \
        -cpu Nehalem,+rdtscp,+pdpe1gb,+dca,+pcid,+pdcm,+xtpr,+tm2,+est,+smx,+vmx,+ds_cpl,+monitor,+dtes64,+pbe,+tm,+ht,+ss,+acpi,+ds,+vme \
        -vnc 0.0.0.0:2${VMID} -device cirrus-vga,id=video0,bus=pci.0,addr=0x2 \
        -serial telnet:0.0.0.0:412${VMID},nowait,server \
        -monitor tcp:0.0.0.0:413${VMID},server,nowait,nodelay \
        -m 4096M -smp 4 \
        -rtc base=utc,driftfix=slew -global kvm-pit.lost_tick_policy=discard -no-hpet \
        -realtime mlock=off \
        -netdev tap,id=s${VMID}30,ifname=tap${VMID}30,script=no,downscript=no -device virtio-net-pci,mac=${vmx_fpc_a},netdev=s${VMID}30,addr=3.0,multifunction=on,id=nic00 \
        -netdev tap,id=s${VMID}31,ifname=tap${VMID}31,script=no,downscript=no -device virtio-net-pci,mac=${vmx_fpc_b},netdev=s${VMID}31,addr=3.1,multifunction=on,id=nic01 \
        \
        -netdev tap,id=t${VMID}10,ifname=tap${VMID}10,script=no,downscript=no -device virtio-net-pci,mac=${vmx_fpc_0},netdev=t${VMID}10,addr=4.0,multifunction=on,id=nic10 \
        -netdev tap,id=t${VMID}11,ifname=tap${VMID}11,script=no,downscript=no -device virtio-net-pci,mac=${vmx_fpc_1},netdev=t${VMID}11,addr=4.1,multifunction=on,id=nic11 \
        -netdev tap,id=t${VMID}12,ifname=tap${VMID}12,script=no,downscript=no -device virtio-net-pci,mac=${vmx_fpc_2},netdev=t${VMID}12,addr=4.2,multifunction=on,id=nic12 \
        -netdev tap,id=t${VMID}13,ifname=tap${VMID}13,script=no,downscript=no -device virtio-net-pci,mac=${vmx_fpc_3},netdev=t${VMID}13,addr=4.3,multifunction=on,id=nic13 \
        -netdev tap,id=t${VMID}14,ifname=tap${VMID}14,script=no,downscript=no -device virtio-net-pci,mac=${vmx_fpc_4},netdev=t${VMID}14,addr=5.0,multifunction=on,id=nic14 \
        -netdev tap,id=t${VMID}15,ifname=tap${VMID}15,script=no,downscript=no -device virtio-net-pci,mac=${vmx_fpc_5},netdev=t${VMID}15,addr=5.1,multifunction=on,id=nic15 \
        -netdev tap,id=t${VMID}16,ifname=tap${VMID}16,script=no,downscript=no -device virtio-net-pci,mac=${vmx_fpc_6},netdev=t${VMID}16,addr=5.2,multifunction=on,id=nic16 \
        -netdev tap,id=t${VMID}17,ifname=tap${VMID}17,script=no,downscript=no -device virtio-net-pci,mac=${vmx_fpc_7},netdev=t${VMID}17,addr=5.3,multifunction=on,id=nic17 \
        -netdev tap,id=t${VMID}18,ifname=tap${VMID}18,script=no,downscript=no -device virtio-net-pci,mac=${vmx_fpc_8},netdev=t${VMID}18,addr=6.0,multifunction=on,id=nic18 \
        -netdev tap,id=t${VMID}19,ifname=tap${VMID}19,script=no,downscript=no -device virtio-net-pci,mac=${vmx_fpc_9},netdev=t${VMID}19,addr=6.1,multifunction=on,id=nic19 \
        -netdev tap,id=t${VMID}20,ifname=tap${VMID}20,script=no,downscript=no -device virtio-net-pci,mac=${vmx_fpc_10},netdev=t${VMID}20,addr=6.2,multifunction=on,id=nic20 \
        -netdev tap,id=t${VMID}21,ifname=tap${VMID}21,script=no,downscript=no -device virtio-net-pci,mac=${vmx_fpc_11},netdev=t${VMID}21,addr=6.3,multifunction=on,id=nic21 \
        -netdev tap,id=t${VMID}22,ifname=tap${VMID}22,script=no,downscript=no -device virtio-net-pci,mac=${vmx_fpc_12},netdev=t${VMID}22,addr=7.0,multifunction=on,id=nic22 \
        -netdev tap,id=t${VMID}23,ifname=tap${VMID}23,script=no,downscript=no -device virtio-net-pci,mac=${vmx_fpc_13},netdev=t${VMID}23,addr=7.1,multifunction=on,id=nic23 \
        -netdev tap,id=t${VMID}24,ifname=tap${VMID}24,script=no,downscript=no -device virtio-net-pci,mac=${vmx_fpc_14},netdev=t${VMID}24,addr=7.2,multifunction=on,id=nic24 \
        -netdev tap,id=t${VMID}25,ifname=tap${VMID}25,script=no,downscript=no -device virtio-net-pci,mac=${vmx_fpc_15},netdev=t${VMID}25,addr=7.3,multifunction=on,id=nic25 \
        -netdev tap,id=t${VMID}26,ifname=tap${VMID}26,script=no,downscript=no -device virtio-net-pci,mac=${vmx_fpc_16},netdev=t${VMID}26,addr=8.0,multifunction=on,id=nic26 \
        -netdev tap,id=t${VMID}27,ifname=tap${VMID}27,script=no,downscript=no -device virtio-net-pci,mac=${vmx_fpc_17},netdev=t${VMID}27,addr=8.1,multifunction=on,id=nic27 \
        -netdev tap,id=t${VMID}28,ifname=tap${VMID}28,script=no,downscript=no -device virtio-net-pci,mac=${vmx_fpc_18},netdev=t${VMID}28,addr=8.2,multifunction=on,id=nic28 \
        -netdev tap,id=t${VMID}29,ifname=tap${VMID}29,script=no,downscript=no -device virtio-net-pci,mac=${vmx_fpc_19},netdev=t${VMID}29,addr=8.3,multifunction=on,id=nic29
        #-L /opt/northstar/thirdparty/qemu/share/qemu \
        #-smbios type=1,product=VM-vmx10${VMID}-mpc-0

}




# main

if [ "$VMTYPE" == "n9kv" ]; then
    init_tap_n9kv
    sleep 2
    launch_n9kv
elif [ "$VMTYPE" == "vmx" ]; then
    init_tap_vmx
    sleep 2
    launch_vmx
else
    echo "VM type $TYPE is not supported"
fi


