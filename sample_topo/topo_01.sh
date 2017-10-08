#!/bin/bash

brctl addbr net-11-21-1
brctl addif net-11-21-1 tap1110
brctl addif net-11-21-1 tap2101
ifconfig net-11-21-1 up

brctl addbr net-11-22-1
brctl addif net-11-22-1 tap1111
brctl addif net-11-22-1 tap2201
ifconfig net-11-22-1 up


brctl addbr net-11-23-1
brctl addif net-11-23-1 tap1112
brctl addif net-11-23-1 tap2301
ifconfig net-11-23-1 up


brctl addbr net-21-22-1
brctl addif net-21-22-1 tap2102
brctl addif net-21-22-1 tap2202
ifconfig net-21-22-1 up

brctl addbr net-11-24-1
brctl addif net-11-24-1 tap1113
brctl addif net-11-24-1 tap2401
ifconfig net-11-24-1 up

brctl addbr net-11-25-1
brctl addif net-11-25-1 tap1114
brctl addif net-11-25-1 tap2501
ifconfig net-11-25-1 up


## ce 101 ##
ip netns add ce-101
ip link add veth_21_101 type veth peer name veth_101_21
ip link set veth_101_21 netns ce-101
ip netns exec ce-101 ip a
ip netns exec ce-101 ifconfig veth_101_21 inet 10.21.1.2 netmask 255.255.255.0 up
ip netns exec ce-101 ip route add default via 10.21.1.1
ip netns exec ce-101 ip link set dev lo up

brctl addbr cenet-21
brctl addif cenet-21 tap2103
brctl addif cenet-21 veth_21_101 
ifconfig cenet-21 up
ifconfig veth_21_101 up
###


## ce 102 mlag  to 21 and 22 ##
ip netns add ce-102
ip link add veth_21_102a type veth peer name veth_102_21a
ip link set veth_102_21a netns ce-102
ip netns exec ce-102 ip a
ip netns exec ce-102 ifconfig veth_102_21a inet 10.21.100.2 netmask 255.255.255.0 up
ip netns exec ce-102 ip route add default via 10.21.100.1
ip netns exec ce-102 ip link set dev lo up

brctl addbr cenet-22a
brctl addif cenet-22a tap2104
brctl addif cenet-22a veth_21_102a 
ifconfig cenet-22a up
ifconfig veth_21_102a up
###



## ce 103 to 23 ##
ip netns add ce-103
ip link add veth_23_103 type veth peer name veth_103_23
ip link set veth_103_23 netns ce-103
ip netns exec ce-103 ip a
ip netns exec ce-103 ifconfig veth_103_23 inet 10.21.100.3 netmask 255.255.255.0 up
ip netns exec ce-103 ip route add default via 10.21.100.1
ip netns exec ce-103 ip link set dev lo up

brctl addbr cenet-23-100
brctl addif cenet-23-100 tap2304
brctl addif cenet-23-100 veth_23_103 
ifconfig cenet-23-100 up
ifconfig veth_23_103 up
###






## ce 110-1 vlan 101 on 21##
ip netns add ce-vx110-101
ip link add veth110_21_101 type veth peer name veth110_101_21
ip link set veth110_101_21 netns ce-vx110-101
ip netns exec ce-vx110-101 ip a
ip netns exec ce-vx110-101 ifconfig veth110_101_21 inet 10.21.101.2 netmask 255.255.255.0 up
ip netns exec ce-vx110-101 ip route add default via 10.21.101.1
ip netns exec ce-vx110-101 ip link set dev lo up

brctl addbr cenet-21-101
brctl addif cenet-21-101 tap2105
brctl addif cenet-21-101 veth110_21_101
ifconfig cenet-21-101 up
ifconfig veth110_21_101 up

###

## ce 110-1 vlan 102 on 23##
ip netns add ce-vx110-102
ip link add veth110_23_102 type veth peer name veth110_102_23
ip link set veth110_102_23 netns ce-vx110-102
ip netns exec ce-vx110-102 ip a
ip netns exec ce-vx110-102 ifconfig veth110_102_23 inet 10.23.102.2 netmask 255.255.255.0 up
ip netns exec ce-vx110-102 ip route add default via 10.23.102.1
ip netns exec ce-vx110-102 ip link set dev lo up

brctl addbr cenet-23-102
brctl addif cenet-23-102 tap2305
brctl addif cenet-23-102 veth110_23_102
ifconfig cenet-23-102 up
ifconfig veth110_23_102 up

###


## ce 110-1 vlan 103 on 23##
ip netns add ce-vx110-103
ip link add veth110_23_103 type veth peer name veth110_103_23
ip link set veth110_103_23 netns ce-vx110-103
ip netns exec ce-vx110-103 ip a
ip netns exec ce-vx110-103 ifconfig veth110_103_23 inet 10.23.103.2 netmask 255.255.255.0 up
ip netns exec ce-vx110-103 ip route add default via 10.23.103.1
ip netns exec ce-vx110-103 ip link set dev lo up

brctl addbr cenet-23-103
brctl addif cenet-23-103 tap2306
brctl addif cenet-23-103 veth110_23_103
ifconfig cenet-23-103 up
ifconfig veth110_23_103 up

###


## ce 110-1 vlan 104 on 21##
ip netns add ce-vx110-104
ip link add veth110_21_104 type veth peer name veth110_104_21
ip link set veth110_104_21 netns ce-vx110-104
ip netns exec ce-vx110-104 ip a
ip netns exec ce-vx110-104 ifconfig veth110_104_21 inet 10.21.104.2 netmask 255.255.255.0 up
ip netns exec ce-vx110-104 ip route add default via 10.21.104.1
ip netns exec ce-vx110-104 ip link set dev lo up

brctl addbr cenet-21-104
brctl addif cenet-21-104 tap2106
brctl addif cenet-21-104 veth110_21_104
ifconfig cenet-21-104 up
ifconfig veth110_21_104 up

###






