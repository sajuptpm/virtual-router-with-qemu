#!/bin/bash

MASTER_IMG_N9KV="/data/kvm/nxosv/nxosv-final.7.0.3.I7.1.qcow2"
MASTER_IMG_VMX_RE="/data/kvm/vmx/junos-vmx-x86-64-17.2-20170519.0.qcow2"
MASTER_IMG_VMX_FPC="/data/kvm/vmx/fpc-17.1.img"
MASTER_IMG_VEOS="/data/kvm/veos/vEOS-lab-4.19.0F-combined.qcow2"
MASTER_IMG_VQFX_FPC="/data/kvm/vqfx/vqfx10k-pfe-20160609-2.qcow2"
MASTER_IMG_VQFX_RE="/data/kvm/vqfx/jinstall-vqfx-10-f-17.3R1.7.img"
MASTER_IMG_CUMULUS="/data/kvm/cumulus-linux-3.3.2-vx-amd64.qcow2"
MASTER_IMG_XR9KV="/data/kvm/xrv9k-fullk9-x-6.0.1.qcow2"
MASTER_IMG_LINUX_REMOTE="http://cloud-images.ubuntu.com/releases/16.04/release/ubuntu-16.04-server-cloudimg-amd64.tar.gz"
MASTER_IMG_LINUX="/data/kvm/xenial-server-cloudimg-amd64-disk1.img"
#MASTER_IMG_VQFX_RE="/data/kvm/vqfx/vqfx10k-re-15.1X53-D60.qcow2"
RUN_FOLDER="/data/kvm/run"

VMID="1"
IP="192.168.1.199"
NETMASK="255.255.255.0"
GW="192.168.1.1"
VMTYPE=""
INIT=0
MGMT_BRIDGE="br1"

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
        --init)
        INIT=1
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
    for i in 00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 16 17 18 19 20; do 
        tunctl -d tap${VMID}${i}
        tunctl -u libvirt-qemu -t tap${VMID}${i}
        ifconfig tap${VMID}${i} up
    done
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
    if [ $INIT -ne 0 ]; then
        prepare_n9kv
    fi
    sleep 2
    VMNAME="n9kv-${VMID}"
    xml="${RUN_FOLDER}/${VMNAME}.xml"
    cp template/kvm/header.n9kv.xml $xml

    sed -i "s/XNAME/${VMNAME}/g" ${xml}
    sed -i "s/VMID/${VMID}/g" ${xml}
    sed -i "s/XCPU/2/g" ${xml}
    sed -i "s/XRAM/8192000/g" ${xml}
    sed -i "s/VMID/${VMID}/g" ${xml}
    sed -i "s/XSERIAL/400${VMID}/g" ${xml}

    echo "    <disk type='file' device='disk'>" >> ${xml}
    echo "      <driver name='qemu' type='qcow2' cache='directsync'/>" >> ${xml}
    echo "      <source file='${RUN_FOLDER}/${VMNAME}.qcow2'/>" >> ${xml}
    echo "      <backingStore/>" >> ${xml}
    echo "      <target dev='hda' bus='ide'/>" >> ${xml}
    echo "      <alias name='ide0-0-0'/>" >> ${xml}
    echo "      <address type='drive' controller='0' bus='0' target='0' unit='0'/>" >> ${xml}
    echo "    </disk>" >> ${xml}

    echo "    <disk type='file' device='cdrom'>" >> ${xml}
    echo "      <driver name='qemu' type='raw'/>" >> ${xml}
    echo "      <source file='${RUN_FOLDER}/n9kv-${VMID}-config.iso'/>" >> ${xml}
    echo "      <target dev='hdc' bus='ide'/>" >> ${xml}
    echo "      <readonly/>" >> ${xml}
    echo "      <address type='drive' controller='0' bus='1' target='0' unit='0'/>" >> ${xml}
    echo "    </disk>" >> ${xml}

    for j in 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20; do
        if [ $j -le 9 ]; then
            i="0${j}" 
        else
            i=$j
        fi
        slot=$((j + 4))
        echo "    <interface type='ethernet'>" >> ${xml}
        echo "      <mac address='52:55:01:00:${VMID}:${i}'/>" >> ${xml}
        echo "      <script path=''/>" >> ${xml}
        echo "      <target dev='tap${VMID}${i}'/>" >> ${xml}
        echo "      <model type='e1000'/>" >> ${xml}
        echo "      <alias name='nic${i}'/>" >> ${xml}
        echo "      <address type='pci' domain='0x0000' bus='0x00' slot='${slot}' function='0x0'/>" >> ${xml}
        echo "    </interface>" >> ${xml}
    done

    cat template/kvm/footer.xml >> $xml
    virsh define $xml
    virsh start ${VMNAME}


#    qemu-system-x86_64 -enable-kvm -hda ${RUN_FOLDER}/n9kv-${VMID}.qcow2 \
#        -cdrom ${RUN_FOLDER}/n9kv-${VMID}-config.iso \
#        -daemonize \
#        -vnc 0.0.0.0:1${VMID} -device cirrus-vga,id=video0,bus=pci.0,addr=0x2 \
#        -bios /usr/share/ovmf/OVMF.fd \
#        -serial telnet:0.0.0.0:410${VMID},nowait,server \
#        -monitor tcp:0.0.0.0:420${VMID},server,nowait,nodelay \
#        -m 8192M -smp 2 \
#        -netdev tap,id=t${VMID}00,ifname=tap${VMID}00,script=no,downscript=no -device e1000,mac=${intf_00},netdev=t${VMID}00,addr=4.0,multifunction=on,id=nic00 \
#        -netdev tap,id=t${VMID}01,ifname=tap${VMID}01,script=no,downscript=no -device e1000,mac=${intf_01},netdev=t${VMID}01,addr=4.1,multifunction=on,id=nic01 \
#        -netdev tap,id=t${VMID}02,ifname=tap${VMID}02,script=no,downscript=no -device e1000,mac=${intf_02},netdev=t${VMID}02,addr=4.2,multifunction=on,id=nic02 \
#        -netdev tap,id=t${VMID}03,ifname=tap${VMID}03,script=no,downscript=no -device e1000,mac=${intf_03},netdev=t${VMID}03,addr=5.0,multifunction=on,id=nic03 \
#        -netdev tap,id=t${VMID}04,ifname=tap${VMID}04,script=no,downscript=no -device e1000,mac=${intf_04},netdev=t${VMID}04,addr=5.1,multifunction=on,id=nic04 \
#        -netdev tap,id=t${VMID}05,ifname=tap${VMID}05,script=no,downscript=no -device e1000,mac=${intf_05},netdev=t${VMID}05,addr=5.2,multifunction=on,id=nic05 \
#        -netdev tap,id=t${VMID}06,ifname=tap${VMID}06,script=no,downscript=no -device e1000,mac=${intf_06},netdev=t${VMID}06,addr=5.3,multifunction=on,id=nic06 \
#        -netdev tap,id=t${VMID}07,ifname=tap${VMID}07,script=no,downscript=no -device e1000,mac=${intf_07},netdev=t${VMID}07,addr=6.0,multifunction=on,id=nic07 \
#        -netdev tap,id=t${VMID}08,ifname=tap${VMID}08,script=no,downscript=no -device e1000,mac=${intf_08},netdev=t${VMID}08,addr=6.1,multifunction=on,id=nic08 \
#        -netdev tap,id=t${VMID}09,ifname=tap${VMID}09,script=no,downscript=no -device e1000,mac=${intf_09},netdev=t${VMID}09,addr=6.2,multifunction=on,id=nic09 \
#        -netdev tap,id=t${VMID}10,ifname=tap${VMID}10,script=no,downscript=no -device e1000,mac=${intf_10},netdev=t${VMID}10,addr=6.3,multifunction=on,id=nic10 

}


prepare_veos () {
    cp ${MASTER_IMG_VEOS} ${RUN_FOLDER}/veos-${VMID}.qcow2
    if [ -d  template/veos-${VMID} ]; then
        rm -rf  template/veos-${VMID}
    fi
    cp -a template/veos template/veos-${VMID}
    sed -i "s/MGMT_IP/${IP}/g" template/veos-${VMID}/NXOS_CONFIG.TXT
    sed -i "s/NETMASK/${NETMASK}/g" template/veos-${VMID}/NXOS_CONFIG.TXT
    sed -i "s/GATEWAY/${GW}/g" template/veos-${VMID}/NXOS_CONFIG.TXT
    mkisofs -l -o  ${RUN_FOLDER}/veos-${VMID}-config.iso template/veos-${VMID}/
}

launch_veos () {
    if [ $INIT -ne 0 ]; then
        prepare_veos
    fi
    sleep 2
    VMNAME="veos-${VMID}"
    xml="${RUN_FOLDER}/${VMNAME}.xml"
    cp template/kvm/header.xml $xml

    sed -i "s/XNAME/${VMNAME}/g" ${xml}
    sed -i "s/VMID/${VMID}/g" ${xml}
    sed -i "s/XCPU/2/g" ${xml}
    sed -i "s/XRAM/4096000/g" ${xml}
    sed -i "s/VMID/${VMID}/g" ${xml}
    sed -i "s/XSERIAL/400${VMID}/g" ${xml}

    echo "    <disk type='file' device='disk'>" >> ${xml}
    echo "      <driver name='qemu' type='qcow2' cache='directsync'/>" >> ${xml}
    echo "      <source file='${RUN_FOLDER}/${VMNAME}.qcow2'/>" >> ${xml}
    echo "      <backingStore/>" >> ${xml}
    echo "      <target dev='hda' bus='ide'/>" >> ${xml}
    echo "      <alias name='ide0-0-0'/>" >> ${xml}
    echo "      <address type='drive' controller='0' bus='0' target='0' unit='0'/>" >> ${xml}
    echo "    </disk>" >> ${xml}


    for j in 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20; do
        if [ $j -le 9 ]; then
            i="0${j}" 
        else
            i=$j
        fi
        slot=$((j + 4))
        echo "    <interface type='ethernet'>" >> ${xml}
        echo "      <mac address='52:55:01:00:${VMID}:${i}'/>" >> ${xml}
        echo "      <script path=''/>" >> ${xml}
        echo "      <target dev='tap${VMID}${i}'/>" >> ${xml}
        echo "      <model type='e1000'/>" >> ${xml}
        echo "      <alias name='nic${i}'/>" >> ${xml}
        echo "      <address type='pci' domain='0x0000' bus='0x00' slot='${slot}' function='0x0'/>" >> ${xml}
        echo "    </interface>" >> ${xml}
    done

    cat template/kvm/footer.xml >> $xml
    virsh define $xml
    virsh start ${VMNAME}

#    qemu-system-x86_64 -enable-kvm -hda ${RUN_FOLDER}/veos-${VMID}.qcow2 \
#        -cdrom ${RUN_FOLDER}/veos-${VMID}-config.iso \
#        -daemonize \
#        -vnc 0.0.0.0:1${VMID} -device cirrus-vga,id=video0,bus=pci.0,addr=0x2 \
#        -serial telnet:0.0.0.0:410${VMID},nowait,server \
#        -monitor tcp:0.0.0.0:420${VMID},server,nowait,nodelay \
#        -m 4192M -smp 2 \
#        -netdev tap,id=t${VMID}00,ifname=tap${VMID}00,script=no,downscript=no -device e1000,mac=${intf_00},netdev=t${VMID}00,addr=4.0,multifunction=on,id=nic00 \
#        -netdev tap,id=t${VMID}01,ifname=tap${VMID}01,script=no,downscript=no -device e1000,mac=${intf_01},netdev=t${VMID}01,addr=4.1,multifunction=on,id=nic01 \
#        -netdev tap,id=t${VMID}02,ifname=tap${VMID}02,script=no,downscript=no -device e1000,mac=${intf_02},netdev=t${VMID}02,addr=4.2,multifunction=on,id=nic02 \
#        -netdev tap,id=t${VMID}03,ifname=tap${VMID}03,script=no,downscript=no -device e1000,mac=${intf_03},netdev=t${VMID}03,addr=5.0,multifunction=on,id=nic03 \
#        -netdev tap,id=t${VMID}04,ifname=tap${VMID}04,script=no,downscript=no -device e1000,mac=${intf_04},netdev=t${VMID}04,addr=5.1,multifunction=on,id=nic04 \
#        -netdev tap,id=t${VMID}05,ifname=tap${VMID}05,script=no,downscript=no -device e1000,mac=${intf_05},netdev=t${VMID}05,addr=5.2,multifunction=on,id=nic05 \
#        -netdev tap,id=t${VMID}06,ifname=tap${VMID}06,script=no,downscript=no -device e1000,mac=${intf_06},netdev=t${VMID}06,addr=5.3,multifunction=on,id=nic06 \
#        -netdev tap,id=t${VMID}07,ifname=tap${VMID}07,script=no,downscript=no -device e1000,mac=${intf_07},netdev=t${VMID}07,addr=6.0,multifunction=on,id=nic07 \
#        -netdev tap,id=t${VMID}08,ifname=tap${VMID}08,script=no,downscript=no -device e1000,mac=${intf_08},netdev=t${VMID}08,addr=6.1,multifunction=on,id=nic08 \
#        -netdev tap,id=t${VMID}09,ifname=tap${VMID}09,script=no,downscript=no -device e1000,mac=${intf_09},netdev=t${VMID}09,addr=6.2,multifunction=on,id=nic09 \
#        -netdev tap,id=t${VMID}10,ifname=tap${VMID}10,script=no,downscript=no -device e1000,mac=${intf_10},netdev=t${VMID}10,addr=6.3,multifunction=on,id=nic10 

}



prepare_cumulus () {
    cp ${MASTER_IMG_CUMULUS} ${RUN_FOLDER}/cumulus-${VMID}.qcow2
}

launch_cumulus () {
    if [ $INIT -ne 0 ]; then
        prepare_cumulus
    fi
    sleep 2
    VMNAME="cumulus-${VMID}"
    xml="${RUN_FOLDER}/${VMNAME}.xml"
    cp template/kvm/header.xml $xml

    sed -i "s/XNAME/${VMNAME}/g" ${xml}
    sed -i "s/VMID/${VMID}/g" ${xml}
    sed -i "s/XCPU/2/g" ${xml}
    sed -i "s/XRAM/4096000/g" ${xml}
    sed -i "s/VMID/${VMID}/g" ${xml}
    sed -i "s/XSERIAL/400${VMID}/g" ${xml}

    echo "    <disk type='file' device='disk'>" >> ${xml}
    echo "      <driver name='qemu' type='qcow2' cache='directsync'/>" >> ${xml}
    echo "      <source file='${RUN_FOLDER}/${VMNAME}.qcow2'/>" >> ${xml}
    echo "      <backingStore/>" >> ${xml}
    echo "      <target dev='hda' bus='ide'/>" >> ${xml}
    echo "      <alias name='ide0-0-0'/>" >> ${xml}
    echo "      <address type='drive' controller='0' bus='0' target='0' unit='0'/>" >> ${xml}
    echo "    </disk>" >> ${xml}

    for j in 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20; do
        if [ $j -le 9 ]; then
            i="0${j}" 
        else
            i=$j
        fi
        slot=$((j + 4))
        echo "    <interface type='ethernet'>" >> ${xml}
        echo "      <mac address='52:55:01:00:${VMID}:${i}'/>" >> ${xml}
        echo "      <script path=''/>" >> ${xml}
        echo "      <target dev='tap${VMID}${i}'/>" >> ${xml}
        echo "      <model type='e1000'/>" >> ${xml}
        echo "      <alias name='nic${i}'/>" >> ${xml}
        echo "      <address type='pci' domain='0x0000' bus='0x00' slot='${slot}' function='0x0'/>" >> ${xml}
        echo "    </interface>" >> ${xml}
    done

    cat template/kvm/footer.xml >> $xml
    virsh define $xml
    virsh start ${VMNAME}
#    qemu-system-x86_64 -enable-kvm -hda ${RUN_FOLDER}/cumulus-${VMID}.qcow2 \
#        -daemonize \
#        -vnc 0.0.0.0:1${VMID} -device cirrus-vga,id=video0,bus=pci.0,addr=0x2 \
#        -serial telnet:0.0.0.0:410${VMID},nowait,server \
#        -monitor tcp:0.0.0.0:420${VMID},server,nowait,nodelay \
#        -m 4192M -smp 2 \
#        -netdev tap,id=t${VMID}00,ifname=tap${VMID}00,script=no,downscript=no -device e1000,mac=${intf_00},netdev=t${VMID}00,addr=4.0,multifunction=on,id=nic00 \
#        -netdev tap,id=t${VMID}01,ifname=tap${VMID}01,script=no,downscript=no -device e1000,mac=${intf_01},netdev=t${VMID}01,addr=4.1,multifunction=on,id=nic01 \
#        -netdev tap,id=t${VMID}02,ifname=tap${VMID}02,script=no,downscript=no -device e1000,mac=${intf_02},netdev=t${VMID}02,addr=4.2,multifunction=on,id=nic02 \
#        -netdev tap,id=t${VMID}03,ifname=tap${VMID}03,script=no,downscript=no -device e1000,mac=${intf_03},netdev=t${VMID}03,addr=5.0,multifunction=on,id=nic03 \
#        -netdev tap,id=t${VMID}04,ifname=tap${VMID}04,script=no,downscript=no -device e1000,mac=${intf_04},netdev=t${VMID}04,addr=5.1,multifunction=on,id=nic04 \
#        -netdev tap,id=t${VMID}05,ifname=tap${VMID}05,script=no,downscript=no -device e1000,mac=${intf_05},netdev=t${VMID}05,addr=5.2,multifunction=on,id=nic05 \
#        -netdev tap,id=t${VMID}06,ifname=tap${VMID}06,script=no,downscript=no -device e1000,mac=${intf_06},netdev=t${VMID}06,addr=5.3,multifunction=on,id=nic06 \
#        -netdev tap,id=t${VMID}07,ifname=tap${VMID}07,script=no,downscript=no -device e1000,mac=${intf_07},netdev=t${VMID}07,addr=6.0,multifunction=on,id=nic07 \
#        -netdev tap,id=t${VMID}08,ifname=tap${VMID}08,script=no,downscript=no -device e1000,mac=${intf_08},netdev=t${VMID}08,addr=6.1,multifunction=on,id=nic08 \
#        -netdev tap,id=t${VMID}09,ifname=tap${VMID}09,script=no,downscript=no -device e1000,mac=${intf_09},netdev=t${VMID}09,addr=6.2,multifunction=on,id=nic09 \
#        -netdev tap,id=t${VMID}10,ifname=tap${VMID}10,script=no,downscript=no -device e1000,mac=${intf_10},netdev=t${VMID}10,addr=6.3,multifunction=on,id=nic10 

}


prepare_xr9kv () {
    cp ${MASTER_IMG_XR9KV} ${RUN_FOLDER}/xr9kv-${VMID}.qcow2
}

launch_xr9kv () {
    if [ $INIT -ne 0 ]; then
        prepare_xr9kv
    fi
    sleep 2
    qemu-system-x86_64 -enable-kvm -hda ${RUN_FOLDER}/xr9kv-${VMID}.qcow2 \
        -daemonize \
        -rtc base=utc \
        -vnc 0.0.0.0:1${VMID} -device cirrus-vga,id=video0,bus=pci.0,addr=0x2 \
        -serial telnet:0.0.0.0:410${VMID},nowait,server \
        -monitor tcp:0.0.0.0:420${VMID},server,nowait,nodelay \
        -m 17000M -smp 4 \
        -netdev tap,id=t${VMID}00,ifname=tap${VMID}00,script=no,downscript=no -device virtio-net-pci,mac=${intf_00},netdev=t${VMID}00,addr=4.0,multifunction=on,id=nic10 \
        -netdev tap,id=t${VMID}01,ifname=tap${VMID}01,script=no,downscript=no -device virtio-net-pci,mac=${intf_01},netdev=t${VMID}01,addr=4.1,multifunction=on,id=nic11 \
        -netdev tap,id=t${VMID}02,ifname=tap${VMID}02,script=no,downscript=no -device virtio-net-pci,mac=${intf_02},netdev=t${VMID}02,addr=4.2,multifunction=on,id=nic12 \
        -netdev tap,id=t${VMID}03,ifname=tap${VMID}03,script=no,downscript=no -device virtio-net-pci,mac=${intf_03},netdev=t${VMID}03,addr=4.3,multifunction=on,id=nic13 \
        -netdev tap,id=t${VMID}04,ifname=tap${VMID}04,script=no,downscript=no -device virtio-net-pci,mac=${intf_04},netdev=t${VMID}04,addr=5.0,multifunction=on,id=nic14 \
        -netdev tap,id=t${VMID}05,ifname=tap${VMID}05,script=no,downscript=no -device virtio-net-pci,mac=${intf_05},netdev=t${VMID}05,addr=5.1,multifunction=on,id=nic15 \
        -netdev tap,id=t${VMID}06,ifname=tap${VMID}06,script=no,downscript=no -device virtio-net-pci,mac=${intf_06},netdev=t${VMID}06,addr=5.2,multifunction=on,id=nic16 \
        -netdev tap,id=t${VMID}07,ifname=tap${VMID}07,script=no,downscript=no -device virtio-net-pci,mac=${intf_07},netdev=t${VMID}07,addr=5.3,multifunction=on,id=nic17 \
        -netdev tap,id=t${VMID}08,ifname=tap${VMID}08,script=no,downscript=no -device virtio-net-pci,mac=${intf_08},netdev=t${VMID}08,addr=6.0,multifunction=on,id=nic18 \
        -netdev tap,id=t${VMID}09,ifname=tap${VMID}09,script=no,downscript=no -device virtio-net-pci,mac=${intf_09},netdev=t${VMID}09,addr=6.1,multifunction=on,id=nic19 \
        -netdev tap,id=t${VMID}10,ifname=tap${VMID}10,script=no,downscript=no -device virtio-net-pci,mac=${intf_10},netdev=t${VMID}10,addr=6.2,multifunction=on,id=nic20 \
        -netdev tap,id=t${VMID}11,ifname=tap${VMID}11,script=no,downscript=no -device virtio-net-pci,mac=${intf_11},netdev=t${VMID}11,addr=6.3,multifunction=on,id=nic21 \
        -netdev tap,id=t${VMID}12,ifname=tap${VMID}12,script=no,downscript=no -device virtio-net-pci,mac=${intf_12},netdev=t${VMID}12,addr=7.0,multifunction=on,id=nic22 \
        -netdev tap,id=t${VMID}13,ifname=tap${VMID}13,script=no,downscript=no -device virtio-net-pci,mac=${intf_13},netdev=t${VMID}13,addr=7.1,multifunction=on,id=nic23 \
        -netdev tap,id=t${VMID}14,ifname=tap${VMID}14,script=no,downscript=no -device virtio-net-pci,mac=${intf_14},netdev=t${VMID}14,addr=7.2,multifunction=on,id=nic24 \
        -netdev tap,id=t${VMID}15,ifname=tap${VMID}15,script=no,downscript=no -device virtio-net-pci,mac=${intf_15},netdev=t${VMID}15,addr=7.3,multifunction=on,id=nic25 \
        -netdev tap,id=t${VMID}16,ifname=tap${VMID}16,script=no,downscript=no -device virtio-net-pci,mac=${intf_16},netdev=t${VMID}16,addr=8.0,multifunction=on,id=nic26 \
        -netdev tap,id=t${VMID}17,ifname=tap${VMID}17,script=no,downscript=no -device virtio-net-pci,mac=${intf_17},netdev=t${VMID}17,addr=8.1,multifunction=on,id=nic27 \
        -netdev tap,id=t${VMID}18,ifname=tap${VMID}18,script=no,downscript=no -device virtio-net-pci,mac=${intf_18},netdev=t${VMID}18,addr=8.2,multifunction=on,id=nic28 \
        -netdev tap,id=t${VMID}19,ifname=tap${VMID}19,script=no,downscript=no -device virtio-net-pci,mac=${intf_19},netdev=t${VMID}19,addr=8.3,multifunction=on,id=nic29 \
        -smbios type=1,manufacturer="cisco",product="Cisco IOS XRv 9000",uuid=97fc351b-431d-4cf2-9c01-43c283faf2a3

#        -netdev tap,id=t${VMID}00,ifname=tap${VMID}00,script=no,downscript=no -device virtio-net-pci,mac=${intf_00},netdev=t${VMID}00,addr=4.0,multifunction=on,id=nic00 \
#        -netdev tap,id=t${VMID}01,ifname=tap${VMID}01,script=no,downscript=no -device virtio-net-pci,mac=${intf_01},netdev=t${VMID}01,addr=4.1,multifunction=on,id=nic01 \
#        -netdev tap,id=t${VMID}02,ifname=tap${VMID}02,script=no,downscript=no -device virtio-net-pci,mac=${intf_02},netdev=t${VMID}02,addr=4.2,multifunction=on,id=nic02 \
#        -netdev tap,id=t${VMID}03,ifname=tap${VMID}03,script=no,downscript=no -device virtio-net-pci,mac=${intf_03},netdev=t${VMID}03,addr=5.0,multifunction=on,id=nic03 \
#        -netdev tap,id=t${VMID}04,ifname=tap${VMID}04,script=no,downscript=no -device virtio-net-pci,mac=${intf_04},netdev=t${VMID}04,addr=5.1,multifunction=on,id=nic04 \
#        -netdev tap,id=t${VMID}05,ifname=tap${VMID}05,script=no,downscript=no -device virtio-net-pci,mac=${intf_05},netdev=t${VMID}05,addr=5.2,multifunction=on,id=nic05 \
#        -netdev tap,id=t${VMID}06,ifname=tap${VMID}06,script=no,downscript=no -device virtio-net-pci,mac=${intf_06},netdev=t${VMID}06,addr=5.3,multifunction=on,id=nic06 \
#        -netdev tap,id=t${VMID}07,ifname=tap${VMID}07,script=no,downscript=no -device virtio-net-pci,mac=${intf_07},netdev=t${VMID}07,addr=6.0,multifunction=on,id=nic07 \
#        -netdev tap,id=t${VMID}08,ifname=tap${VMID}08,script=no,downscript=no -device virtio-net-pci,mac=${intf_08},netdev=t${VMID}08,addr=6.1,multifunction=on,id=nic08 \
#        -netdev tap,id=t${VMID}09,ifname=tap${VMID}09,script=no,downscript=no -device virtio-net-pci,mac=${intf_09},netdev=t${VMID}09,addr=6.2,multifunction=on,id=nic09 \
#        -netdev tap,id=t${VMID}10,ifname=tap${VMID}10,script=no,downscript=no -device virtio-net-pci,mac=${intf_10},netdev=t${VMID}10,addr=6.3,multifunction=on,id=nic10 \
}




init_tap_vmx() {
    for i in 00 01 30 31 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24; do 
        tunctl -d tap${VMID}${i}
        tunctl -u libvirt-qemu -t tap${VMID}${i}
        ifconfig tap${VMID}${i} up
    done
    
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
    #cp ${MASTER_IMG_VMX_RE} ${RUN_FOLDER}/vmx-${VMID}-re.qcow2
    #cp ${MASTER_IMG_VMX_FPC} ${RUN_FOLDER}/vmx-${VMID}-fpc.img
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
    if [ $INIT -ne 0 ]; then
        prepare_vmx
    fi
    sleep 2
    
    # RE part
    VMNAME="vmx-${VMID}-re"
    virsh destroy $VMNAME
    virsh undefine $VMNAME

    xml="${RUN_FOLDER}/${VMNAME}.xml"
    cp template/kvm/header.xml $xml

    sed -i "s/XNAME/${VMNAME}/g" ${xml}
    sed -i "s/VMID/${VMID}/g" ${xml}
    sed -i "s/XCPU/1/g" ${xml}
    sed -i "s/XRAM/4096000/g" ${xml}
    sed -i "s/VMID/${VMID}/g" ${xml}
    sed -i "s/XSERIAL/400${VMID}/g" ${xml}

    echo "    <disk type='file' device='disk'>" >> ${xml}
    echo "      <driver name='qemu' type='qcow2' cache='directsync'/>" >> ${xml}
    echo "      <source file='${RUN_FOLDER}/${VMNAME}.qcow2'/>" >> ${xml}
    echo "      <backingStore/>" >> ${xml}
    echo "      <target dev='hda' bus='ide'/>" >> ${xml}
    echo "      <alias name='ide0-0-0'/>" >> ${xml}
    echo "      <address type='drive' controller='0' bus='0' target='0' unit='0'/>" >> ${xml}
    echo "    </disk>" >> ${xml}

    echo "    <disk type='file' device='disk'>" >> ${xml}
    echo "      <driver name='qemu' type='raw' cache='directsync'/>" >> ${xml}
    echo "      <source file='${RUN_FOLDER}/${VMNAME}-config.img'/>" >> ${xml}
    echo "      <backingStore/>" >> ${xml}
    echo "      <target dev='hdb' bus='ide'/>" >> ${xml}
    echo "      <alias name='ide0-0-1'/>" >> ${xml}
    echo "      <address type='drive' controller='0' bus='0' target='0' unit='1'/>" >> ${xml}
    echo "    </disk>" >> ${xml}

    for j in 0 1; do
        if [ $j -le 9 ]; then
            i="0${j}" 
        else
            i=$j
        fi
        slot=$((j + 4))
        echo "    <interface type='ethernet'>" >> ${xml}
        echo "      <mac address='52:55:00:00:${VMID}:${i}'/>" >> ${xml}
        echo "      <script path=''/>" >> ${xml}
        echo "      <target dev='tap${VMID}${i}'/>" >> ${xml}
        echo "      <model type='virtio'/>" >> ${xml}
        echo "      <alias name='nic${i}'/>" >> ${xml}
        echo "      <address type='pci' domain='0x0000' bus='0x00' slot='${slot}' function='0x0'/>" >> ${xml}
        echo "    </interface>" >> ${xml}
    done

    cat template/kvm/footer.xml >> $xml
    virsh define $xml
    virsh start $VMNAME
    
#    qemu-system-x86_64 -snapshot -enable-kvm -hda ${RUN_FOLDER}/vmx-${VMID}-re.qcow2 \
#        -hdb ${RUN_FOLDER}/vmx-${VMID}-re-config.img \
#        -machine pc-i440fx-xenial,accel=kvm,usb=off \
#        -cpu Nehalem,+rdtscp,+pdpe1gb,+dca,+pcid,+pdcm,+xtpr,+tm2,+est,+smx,+vmx,+ds_cpl,+monitor,+dtes64,+pbe,+tm,+ht,+ss,+acpi,+ds,+vme \
#        -daemonize \
#        -rtc base=utc,driftfix=slew -global kvm-pit.lost_tick_policy=discard -no-hpet \
#        -realtime mlock=off \
#        -vnc 0.0.0.0:1${VMID} -device cirrus-vga,id=video0,bus=pci.0,addr=0x2 \
#        -serial telnet:0.0.0.0:410${VMID},nowait,server \
#        -monitor tcp:0.0.0.0:411${VMID},server,nowait,nodelay \
#        -m 4096M -smp 1 \
#        -netdev tap,id=t${VMID}00,ifname=tap${VMID}00,script=no,downscript=no -device virtio-net-pci,mac=${vmx_re_a},netdev=t${VMID}00,addr=3.0,multifunction=on,id=nic00 \
#        -netdev tap,id=t${VMID}01,ifname=tap${VMID}01,script=no,downscript=no -device virtio-net-pci,mac=${vmx_re_b},netdev=t${VMID}01,addr=3.1,multifunction=on,id=nic01 \
#        #-L /opt/northstar/thirdparty/qemu/share/qemu \
#        #-smbios type=1,product=VM-vmx10${VMID}-re-0
    

    # FPC part
    VMNAME="vmx-${VMID}-fpc"
    virsh destroy $VMNAME
    virsh undefine $VMNAME
    
    xml="${RUN_FOLDER}/${VMNAME}.xml"
    cp template/kvm/header.xml $xml

    sed -i "s/XNAME/${VMNAME}/g" ${xml}
    sed -i "s/VMID/${VMID}/g" ${xml}
    sed -i "s/XCPU/4/g" ${xml}
    sed -i "s/XRAM/4196000/g" ${xml}
    sed -i "s/VMID/${VMID}/g" ${xml}
    sed -i "s/XSERIAL/402${VMID}/g" ${xml}

    echo "    <disk type='file' device='disk'>" >> ${xml}
    echo "      <driver name='qemu' type='raw' cache='directsync'/>" >> ${xml}
    echo "      <source file='${RUN_FOLDER}/${VMNAME}.img'/>" >> ${xml}
    echo "      <backingStore/>" >> ${xml}
    echo "      <target dev='hda' bus='ide'/>" >> ${xml}
    echo "      <alias name='ide0-0-0'/>" >> ${xml}
    echo "      <address type='drive' controller='0' bus='0' target='0' unit='0'/>" >> ${xml}
    echo "    </disk>" >> ${xml}

    for j in 30 31; do
        if [ $j -le 9 ]; then
            i="0${j}" 
        else
            i=$j
        fi
        slot=$((j - 26))
        echo "    <interface type='ethernet'>" >> ${xml}
        echo "      <mac address='52:55:00:01:${VMID}:${i}'/>" >> ${xml}
        echo "      <script path=''/>" >> ${xml}
        echo "      <target dev='tap${VMID}${i}'/>" >> ${xml}
        echo "      <model type='virtio'/>" >> ${xml}
        echo "      <alias name='nic${i}'/>" >> ${xml}
        echo "      <address type='pci' domain='0x0000' bus='0x00' slot='${slot}' function='0x0'/>" >> ${xml}
        echo "    </interface>" >> ${xml}
    done

    for j in 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24; do
        if [ $j -le 9 ]; then
            i="0${j}" 
        else
            i=$j
        fi
        slot=$((j - 4))
        echo "    <interface type='ethernet'>" >> ${xml}
        echo "      <mac address='52:55:00:02:${VMID}:${i}'/>" >> ${xml}
        echo "      <script path=''/>" >> ${xml}
        echo "      <target dev='tap${VMID}${i}'/>" >> ${xml}
        echo "      <model type='virtio'/>" >> ${xml}
        echo "      <alias name='nic${i}'/>" >> ${xml}
        echo "      <address type='pci' domain='0x0000' bus='0x00' slot='${slot}' function='0x0'/>" >> ${xml}
        echo "    </interface>" >> ${xml}
    done
    cat template/kvm/footer.xml >> $xml
    virsh define $xml
    virsh start $VMNAME
    

#    qemu-system-x86_64 -snapshot -enable-kvm -hda ${RUN_FOLDER}/vmx-${VMID}-fpc.img \
#        -daemonize \
#        -machine pc-i440fx-xenial,accel=kvm,usb=off \
#        -cpu Nehalem,+rdtscp,+pdpe1gb,+dca,+pcid,+pdcm,+xtpr,+tm2,+est,+smx,+vmx,+ds_cpl,+monitor,+dtes64,+pbe,+tm,+ht,+ss,+acpi,+ds,+vme \
#        -vnc 0.0.0.0:2${VMID} -device cirrus-vga,id=video0,bus=pci.0,addr=0x2 \
#        -serial telnet:0.0.0.0:412${VMID},nowait,server \
#        -monitor tcp:0.0.0.0:413${VMID},server,nowait,nodelay \
#        -m 4096M -smp 4 \
#        -rtc base=utc,driftfix=slew -global kvm-pit.lost_tick_policy=discard -no-hpet \
#        -realtime mlock=off \
#        -netdev tap,id=s${VMID}30,ifname=tap${VMID}30,script=no,downscript=no -device virtio-net-pci,mac=${vmx_fpc_a},netdev=s${VMID}30,addr=3.0,multifunction=on,id=nic00 \
#        -netdev tap,id=s${VMID}31,ifname=tap${VMID}31,script=no,downscript=no -device virtio-net-pci,mac=${vmx_fpc_b},netdev=s${VMID}31,addr=3.1,multifunction=on,id=nic01 \
#        \
#        -netdev tap,id=t${VMID}10,ifname=tap${VMID}10,script=no,downscript=no -device virtio-net-pci,mac=${vmx_fpc_0},netdev=t${VMID}10,addr=4.0,multifunction=on,id=nic10 \
#        -netdev tap,id=t${VMID}11,ifname=tap${VMID}11,script=no,downscript=no -device virtio-net-pci,mac=${vmx_fpc_1},netdev=t${VMID}11,addr=4.1,multifunction=on,id=nic11 \
#        -netdev tap,id=t${VMID}12,ifname=tap${VMID}12,script=no,downscript=no -device virtio-net-pci,mac=${vmx_fpc_2},netdev=t${VMID}12,addr=4.2,multifunction=on,id=nic12 \
#        -netdev tap,id=t${VMID}13,ifname=tap${VMID}13,script=no,downscript=no -device virtio-net-pci,mac=${vmx_fpc_3},netdev=t${VMID}13,addr=4.3,multifunction=on,id=nic13 \
#        -netdev tap,id=t${VMID}14,ifname=tap${VMID}14,script=no,downscript=no -device virtio-net-pci,mac=${vmx_fpc_4},netdev=t${VMID}14,addr=5.0,multifunction=on,id=nic14 \
#        -netdev tap,id=t${VMID}15,ifname=tap${VMID}15,script=no,downscript=no -device virtio-net-pci,mac=${vmx_fpc_5},netdev=t${VMID}15,addr=5.1,multifunction=on,id=nic15 \
#        -netdev tap,id=t${VMID}16,ifname=tap${VMID}16,script=no,downscript=no -device virtio-net-pci,mac=${vmx_fpc_6},netdev=t${VMID}16,addr=5.2,multifunction=on,id=nic16 \
#        -netdev tap,id=t${VMID}17,ifname=tap${VMID}17,script=no,downscript=no -device virtio-net-pci,mac=${vmx_fpc_7},netdev=t${VMID}17,addr=5.3,multifunction=on,id=nic17 \
#        -netdev tap,id=t${VMID}18,ifname=tap${VMID}18,script=no,downscript=no -device virtio-net-pci,mac=${vmx_fpc_8},netdev=t${VMID}18,addr=6.0,multifunction=on,id=nic18 \
#        -netdev tap,id=t${VMID}19,ifname=tap${VMID}19,script=no,downscript=no -device virtio-net-pci,mac=${vmx_fpc_9},netdev=t${VMID}19,addr=6.1,multifunction=on,id=nic19 \
#        -netdev tap,id=t${VMID}20,ifname=tap${VMID}20,script=no,downscript=no -device virtio-net-pci,mac=${vmx_fpc_10},netdev=t${VMID}20,addr=6.2,multifunction=on,id=nic20 \
#        -netdev tap,id=t${VMID}21,ifname=tap${VMID}21,script=no,downscript=no -device virtio-net-pci,mac=${vmx_fpc_11},netdev=t${VMID}21,addr=6.3,multifunction=on,id=nic21 \
#        -netdev tap,id=t${VMID}22,ifname=tap${VMID}22,script=no,downscript=no -device virtio-net-pci,mac=${vmx_fpc_12},netdev=t${VMID}22,addr=7.0,multifunction=on,id=nic22 \
#        -netdev tap,id=t${VMID}23,ifname=tap${VMID}23,script=no,downscript=no -device virtio-net-pci,mac=${vmx_fpc_13},netdev=t${VMID}23,addr=7.1,multifunction=on,id=nic23 \
#        -netdev tap,id=t${VMID}24,ifname=tap${VMID}24,script=no,downscript=no -device virtio-net-pci,mac=${vmx_fpc_14},netdev=t${VMID}24,addr=7.2,multifunction=on,id=nic24 \
#        -netdev tap,id=t${VMID}25,ifname=tap${VMID}25,script=no,downscript=no -device virtio-net-pci,mac=${vmx_fpc_15},netdev=t${VMID}25,addr=7.3,multifunction=on,id=nic25 \
#        -netdev tap,id=t${VMID}26,ifname=tap${VMID}26,script=no,downscript=no -device virtio-net-pci,mac=${vmx_fpc_16},netdev=t${VMID}26,addr=8.0,multifunction=on,id=nic26 \
#        -netdev tap,id=t${VMID}27,ifname=tap${VMID}27,script=no,downscript=no -device virtio-net-pci,mac=${vmx_fpc_17},netdev=t${VMID}27,addr=8.1,multifunction=on,id=nic27 \
#        -netdev tap,id=t${VMID}28,ifname=tap${VMID}28,script=no,downscript=no -device virtio-net-pci,mac=${vmx_fpc_18},netdev=t${VMID}28,addr=8.2,multifunction=on,id=nic28 \
#        -netdev tap,id=t${VMID}29,ifname=tap${VMID}29,script=no,downscript=no -device virtio-net-pci,mac=${vmx_fpc_19},netdev=t${VMID}29,addr=8.3,multifunction=on,id=nic29
#        #-L /opt/northstar/thirdparty/qemu/share/qemu \
#        #-smbios type=1,product=VM-vmx10${VMID}-mpc-0

}






init_tap_vqfx () {
    for i in 00 01 02 30 31 32 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29; do 
        tunctl -d tap${VMID}${i}
        tunctl -u libvirt-qemu -t tap${VMID}${i}
        ifconfig tap${VMID}${i} up
    done
    
    #management
    brctl addif ${MGMT_BRIDGE} tap${VMID}00
    brctl addif ${MGMT_BRIDGE} tap${VMID}30
    
    #RE-to-FPC
    brctl addbr vqfx${VMID}01_re
    ifconfig vqfx${VMID}01_re up
    brctl addif vqfx${VMID}01_re tap${VMID}01
    brctl addif vqfx${VMID}01_re tap${VMID}31

    brctl addbr vqfx${VMID}01_fpc
    ifconfig vqfx${VMID}01_fpc up
    brctl addif vqfx${VMID}01_fpc tap${VMID}02
    #brctl addif vqfx${VMID}01_fpc tap${VMID}32
    
}




prepare_vqfx () {
    cp ${MASTER_IMG_VQFX_RE} ${RUN_FOLDER}/vqfx-${VMID}-re.qcow2
    cp ${MASTER_IMG_VQFX_FPC} ${RUN_FOLDER}/vqfx-${VMID}-fpc.qcow2
}



launch_vqfx() {
    if [ $INIT -ne 0 ]; then
        prepare_vqfx
    fi
    sleep 2
    
    # RE part
    VMNAME="vqfx-${VMID}-re"
    xml="${RUN_FOLDER}/${VMNAME}.xml"
    cp template/kvm/header.xml $xml

    sed -i "s/XNAME/vqfx-${VMID}-re/g" ${xml}
    sed -i "s/VMID/${VMID}/g" ${xml}
    sed -i "s/XCPU/1/g" ${xml}
    sed -i "s/XRAM/1024000/g" ${xml}
    sed -i "s/VMID/${VMID}/g" ${xml}
    sed -i "s/XSERIAL/400${VMID}/g" ${xml}

    echo "    <disk type='file' device='disk'>" >> ${xml}
    echo "      <driver name='qemu' type='qcow2' cache='directsync'/>" >> ${xml}
    echo "      <source file='${RUN_FOLDER}/vqfx-${VMID}-re.qcow2'/>" >> ${xml}
    echo "      <backingStore/>" >> ${xml}
    echo "      <target dev='hda' bus='ide'/>" >> ${xml}
    echo "      <alias name='ide0-0-0'/>" >> ${xml}
    echo "      <address type='drive' controller='0' bus='0' target='0' unit='0'/>" >> ${xml}
    echo "    </disk>" >> ${xml}

    for j in 0 1 2; do
        if [ $j -le 9 ]; then
            i="0${j}" 
        else
            i=$j
        fi
        slot=$((j + 4))
        echo "    <interface type='ethernet'>" >> ${xml}
        echo "      <mac address='52:55:01:00:${VMID}:${i}'/>" >> ${xml}
        echo "      <script path=''/>" >> ${xml}
        echo "      <target dev='tap${VMID}${i}'/>" >> ${xml}
        echo "      <model type='e1000'/>" >> ${xml}
        echo "      <alias name='nic${i}'/>" >> ${xml}
        echo "      <address type='pci' domain='0x0000' bus='0x00' slot='${slot}' function='0x0'/>" >> ${xml}
        echo "    </interface>" >> ${xml}
    done

    for j in 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24; do
        if [ $j -le 9 ]; then
            i="0${j}" 
        else
            i=$j
        fi
        slot=$((j + 7))
        echo "    <interface type='ethernet'>" >> ${xml}
        echo "      <mac address='52:55:01:01:${VMID}:${i}'/>" >> ${xml}
        echo "      <script path=''/>" >> ${xml}
        echo "      <target dev='tap${VMID}${i}'/>" >> ${xml}
        echo "      <model type='e1000'/>" >> ${xml}
        echo "      <alias name='nic${i}'/>" >> ${xml}
        echo "      <address type='pci' domain='0x0000' bus='0x00' slot='${slot}' function='0x0'/>" >> ${xml}
        echo "    </interface>" >> ${xml}
    done
    cat template/kvm/footer.xml >> $xml
    virsh define $xml
    virsh start $VMNAME
    
    # PFE part
    VMNAME="vqfx-${VMID}-fpc"
    xml="${RUN_FOLDER}/${VMNAME}.xml"
    cp template/kvm/header.xml $xml

    sed -i "s/XNAME/vqfx-${VMID}-fpc/g" ${xml}
    sed -i "s/VMID/${VMID}/g" ${xml}
    sed -i "s/XCPU/1/g" ${xml}
    sed -i "s/XRAM/2148000/g" ${xml}
    sed -i "s/VMID/${VMID}/g" ${xml}
    sed -i "s/XSERIAL/402${VMID}/g" ${xml}

    echo "    <disk type='file' device='disk'>" >> ${xml}
    echo "      <driver name='qemu' type='qcow2' cache='directsync'/>" >> ${xml}
    echo "      <source file='${RUN_FOLDER}/vqfx-${VMID}-fpc.qcow2'/>" >> ${xml}
    echo "      <backingStore/>" >> ${xml}
    echo "      <target dev='hda' bus='ide'/>" >> ${xml}
    echo "      <alias name='ide0-0-0'/>" >> ${xml}
    echo "      <address type='drive' controller='0' bus='0' target='0' unit='0'/>" >> ${xml}
    echo "    </disk>" >> ${xml}

    for j in 30 31; do
        if [ $j -le 9 ]; then
            i="0${j}" 
        else
            i=$j
        fi
        slot=$((j - 26))
        echo "    <interface type='ethernet'>" >> ${xml}
        echo "      <mac address='52:55:01:02:${VMID}:${i}'/>" >> ${xml}
        echo "      <script path=''/>" >> ${xml}
        echo "      <target dev='tap${VMID}${i}'/>" >> ${xml}
        echo "      <model type='e1000'/>" >> ${xml}
        echo "      <alias name='nic${i}'/>" >> ${xml}
        echo "      <address type='pci' domain='0x0000' bus='0x00' slot='${slot}' function='0x0'/>" >> ${xml}
        echo "    </interface>" >> ${xml}
    done

    cat template/kvm/footer.xml >> $xml
    virsh define $xml
    virsh start $VMNAME
    

}



init_tap_linux () {
    for i in 00 01 02 03 04 05 06 07 08 09; do 
        tunctl -d tap${VMID}${i}
        tunctl -u libvirt-qemu -t tap${VMID}${i}
        ifconfig tap${VMID}${i} up
    done
    brctl addif ${MGMT_BRIDGE} tap${VMID}00
}
   


prepare_linux () {
    cp ${MASTER_IMG_LINUX} ${RUN_FOLDER}/linux-${VMID}.img
    if [ -d  template/linux-${VMID} ]; then
        rm -rf  template/linux-${VMID}
    fi
    cp -a template/kvm/linux template/linux-${VMID}
    sed -i "s/MGMT_IP/${IP}/g" template/linux-${VMID}/*
    sed -i "s/NETMASK/${NETMASK}/g" template/linux-${VMID}/*
    sed -i "s/GATEWAY/${GW}/g" template/linux-${VMID}/*
    #cloud-localds ${RUN_FOLDER}/linux-${VMID}-config.img template/linux-${VMID}/my-user-data 
    #cloud-localds ${RUN_FOLDER}/linux-${VMID}-config.img template/linux-${VMID}/meta-data
    cd template/linux-${VMID}
    genisoimage -o ${RUN_FOLDER}/linux-${VMID}-config.iso -V cidata -r -J meta-data user-data network-config
    cd ../..
}


launch_linux () {
    if [ $INIT -ne 0 ]; then
        prepare_linux
    fi
    sleep 2
    VMNAME="linux-${VMID}"
    xml="${RUN_FOLDER}/${VMNAME}.xml"
    cp template/kvm/header.xml $xml

    sed -i "s/XNAME/${VMNAME}/g" ${xml}
    sed -i "s/VMID/${VMID}/g" ${xml}
    sed -i "s/XCPU/2/g" ${xml}
    sed -i "s/XRAM/8192000/g" ${xml}
    sed -i "s/VMID/${VMID}/g" ${xml}
    sed -i "s/XSERIAL/400${VMID}/g" ${xml}

    echo "    <disk type='file' device='disk'>" >> ${xml}
    echo "      <driver name='qemu' type='qcow2' cache='directsync'/>" >> ${xml}
    echo "      <source file='${RUN_FOLDER}/${VMNAME}.img'/>" >> ${xml}
    echo "      <backingStore/>" >> ${xml}
    echo "      <target dev='hda' bus='ide'/>" >> ${xml}
    echo "      <alias name='ide0-0-0'/>" >> ${xml}
    echo "      <address type='drive' controller='0' bus='0' target='0' unit='0'/>" >> ${xml}
    echo "    </disk>" >> ${xml}

    echo "    <disk type='file' device='cdrom'>" >> ${xml}
    echo "      <driver name='qemu' type='raw'/>" >> ${xml}
    echo "      <source file='${RUN_FOLDER}/linux-${VMID}-config.iso'/>" >> ${xml}
    echo "      <target dev='hdc' bus='ide'/>" >> ${xml}
    echo "      <readonly/>" >> ${xml}
    echo "      <address type='drive' controller='0' bus='1' target='0' unit='0'/>" >> ${xml}
    echo "    </disk>" >> ${xml}

    for j in 0 1 2 3 4 5 6 7 8 9; do
        if [ $j -le 9 ]; then
            i="0${j}" 
        else
            i=$j
        fi
        slot=$((j + 4))
        echo "    <interface type='ethernet'>" >> ${xml}
        echo "      <mac address='52:55:01:00:${VMID}:${i}'/>" >> ${xml}
        echo "      <script path=''/>" >> ${xml}
        echo "      <target dev='tap${VMID}${i}'/>" >> ${xml}
        echo "      <model type='virtio'/>" >> ${xml}
        echo "      <alias name='nic${i}'/>" >> ${xml}
        echo "      <address type='pci' domain='0x0000' bus='0x00' slot='${slot}' function='0x0'/>" >> ${xml}
        echo "    </interface>" >> ${xml}
    done

    cat template/kvm/footer.xml >> $xml
    virsh define $xml
    virsh start ${VMNAME}
}






# main

if [ "$VMTYPE" == "n9kv" ]; then
    init_tap_n9kv
    sleep 2
    launch_n9kv
elif [ "$VMTYPE" == "veos" ]; then
    init_tap_n9kv
    sleep 2
    launch_veos
elif [ "$VMTYPE" == "xr9kv" ]; then
    init_tap_n9kv
    sleep 2
    launch_xr9kv
elif [ "$VMTYPE" == "cumulus" ]; then
    init_tap_n9kv
    sleep 2
    launch_cumulus
elif [ "$VMTYPE" == "vmx" ]; then
    init_tap_vmx
    sleep 2
    launch_vmx
elif [ "$VMTYPE" == "vqfx" ]; then
    init_tap_vqfx
    sleep 2
    launch_vqfx
elif [ "$VMTYPE" == "linux" ]; then
    init_tap_linux
    sleep 2
    launch_linux
else
    echo "VM type $TYPE is not supported"
fi


