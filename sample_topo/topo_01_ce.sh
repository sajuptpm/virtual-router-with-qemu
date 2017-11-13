#!/bin/bash

## vmx logical-system ce trunk to leaf-22
brctl addbr net-11-22-2
brctl addif net-11-22-2 tap1119
brctl addif net-11-22-2 tap2209
ifconfig net-11-22-2 up


#ce of n9kv-21
../create_ce.sh ce-21-100 10.21.100.121/24 10.21.100.1 tap2104
../create_ce.sh ce-21-121 10.21.121.2/24 10.21.121.1 tap2105
../create_ce.sh ce-21-221 10.21.221.2/24 10.21.221.1 tap2106


#ce of n9kv-23
../create_ce.sh ce-23-200 10.23.200.123/24 10.23.200.1 tap2307
../create_ce.sh ce-23-123 10.23.123.2/24 10.23.123.1 tap2305
../create_ce.sh ce-23-223 10.23.223.2/24 10.23.223.1 tap2306


#ce of veos-24
../create_ce.sh ce-24-100 10.21.100.124/24 10.21.100.1 tap2402
../create_ce.sh ce-24-124 10.24.124.2/24 10.24.124.1 tap2403

#ce of veos-25
../create_ce.sh ce-25-100 10.21.100.125/24 10.21.100.1 tap2502
../create_ce.sh ce-25-125 10.25.125.2/24 10.25.125.1 tap2503
../create_ce.sh ce-25-200 10.23.200.125/24 10.23.200.1 tap2504

#ce of vqfx-26
../create_ce.sh ce-26-100 10.21.100.126/24 10.21.100.1 tap2612
../create_ce.sh ce-26-126 10.26.126.2/24 10.26.126.1 tap2613

#ce of vqfx-28
../create_ce.sh ce-28-100 10.21.100.128/24 10.21.100.1 tap2812
../create_ce.sh ce-28-128 10.28.128.2/24 10.28.128.1 tap2813



##
## ce 101 non-irb begin
##
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
## ce 101 non-irb end


##
## vlan 100 at 21
##
ip netns add ce-21-100
ip link add veth_21_100 type veth peer name veth_100_21
ip link set veth_100_21 netns ce-21-100
ip netns exec ce-21-100 ip a
ip netns exec ce-21-100 ifconfig veth_100_21 inet 10.21.100.2 netmask 255.255.255.0 up
ip netns exec ce-21-100 ip route add default via 10.21.100.1
ip netns exec ce-21-100 ip link set dev lo up

brctl addbr cenet-21-100                                                                                                                
brctl addif cenet-21-100 tap2104
brctl addif cenet-21-100 veth_21_100
ifconfig cenet-21-100 up
ifconfig veth_21_100 up
###



##
## vlan 100 at 23
##
ip netns add ce-23-100
ip link add veth_23_100 type veth peer name veth_100_23
ip link set veth_100_23 netns ce-23-100
ip netns exec ce-23-100 ip a
ip netns exec ce-23-100 ifconfig veth_100_23 inet 10.21.100.3 netmask 255.255.255.0 up
ip netns exec ce-23-100 ip route add default via 10.21.100.1
ip netns exec ce-23-100 ip link set dev lo up

brctl addbr cenet-23-100
brctl addif cenet-23-100 tap2304
brctl addif cenet-23-100 veth_23_100 
ifconfig cenet-23-100 up
ifconfig veth_23_100 up
###





##
## vlan 101 on 21##
##
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



##
## vlan 102 on 23 #
##
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



##
## vlan 103 on 23
##
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




##
## vlan 104 on 21
##
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







################### veos ce ####################

##
## vlan 100 on 24##
##
ip netns add ce-24-100
ip link add veth_24_100 type veth peer name veth_100_24
ip link set veth_100_24 netns ce-24-100
ip netns exec ce-24-100 ip a
ip netns exec ce-24-100 ifconfig veth_100_24 inet 10.21.100.124 netmask 255.255.255.0 up
ip netns exec ce-24-100 ip route add default via 10.21.100.1
ip netns exec ce-24-100 ip link set dev lo up

brctl addbr cenet-24-100
brctl addif cenet-24-100 tap2402
brctl addif cenet-24-100 veth_24_100
ifconfig cenet-24-100 up
ifconfig veth_24_100 up
###



##
## vlan 124 on 24##
##
ip netns add ce-vx110-124
ip link add veth110_24_124 type veth peer name veth110_124_24
ip link set veth110_124_24 netns ce-vx110-124
ip netns exec ce-vx110-124 ip a
ip netns exec ce-vx110-124 ifconfig veth110_124_24 inet 10.24.124.2 netmask 255.255.255.0 up
ip netns exec ce-vx110-124 ip route add default via 10.24.124.1
ip netns exec ce-vx110-124 ip link set dev lo up

brctl addbr cenet-24-124
brctl addif cenet-24-124 tap2403
brctl addif cenet-24-124 veth110_24_124
ifconfig cenet-24-124 up
ifconfig veth110_24_124 up
###




##
## vlan 100 on 25##
##
ip netns add ce-25-100
ip link add veth_25_100 type veth peer name veth_100_25
ip link set veth_100_25 netns ce-25-100
ip netns exec ce-25-100 ip a
ip netns exec ce-25-100 ifconfig veth_100_25 inet 10.21.100.125 netmask 255.255.255.0 up
ip netns exec ce-25-100 ip route add default via 10.21.100.1
ip netns exec ce-25-100 ip link set dev lo up

brctl addbr cenet-25-100
brctl addif cenet-25-100 tap2502
brctl addif cenet-25-100 veth_25_100
ifconfig cenet-25-100 up
ifconfig veth_25_100 up
###



## vlan 125 on 25##
ip netns add ce-vx110-125
ip link add veth110_25_125 type veth peer name veth110_125_25
ip link set veth110_125_25 netns ce-vx110-125
ip netns exec ce-vx110-125 ip a
ip netns exec ce-vx110-125 ifconfig veth110_125_25 inet 10.25.125.2 netmask 255.255.255.0 up
ip netns exec ce-vx110-125 ip route add default via 10.25.125.1
ip netns exec ce-vx110-125 ip link set dev lo up

brctl addbr cenet-25-125
brctl addif cenet-25-125 tap2503
brctl addif cenet-25-125 veth110_25_125
ifconfig cenet-25-125 up
ifconfig veth110_25_125 up
###






###### vmx ce #####

##
## vlan 100 on 11##
##
ip netns add ce-11-100
ip link add veth_11_100 type veth peer name veth_100_11
ip link set veth_100_11 netns ce-11-100
ip netns exec ce-11-100 ip a
ip netns exec ce-11-100 ifconfig veth_100_11 inet 10.21.100.111 netmask 255.255.255.0  up
ip netns exec ce-11-100 ip route add default via 10.21.100.1
ip netns exec ce-11-100 ip link set dev lo up

brctl addbr cenet-11-100
brctl addif cenet-11-100 tap1116
brctl addif cenet-11-100 veth_11_100
ifconfig cenet-11-100 up
ifconfig veth_11_100 up
###



##
## vlan 111 on 11##
##
ip netns add ce-vx110-111
ip link add veth110_11_111 type veth peer name veth110_111_11
ip link set veth110_111_11 netns ce-vx110-111
ip netns exec ce-vx110-111 ip a
ip netns exec ce-vx110-111 ifconfig veth110_111_11 inet 10.11.111.2 netmask 115.115.115.0 up
ip netns exec ce-vx110-111 ip route add default via 10.11.111.1
ip netns exec ce-vx110-111 ip link set dev lo up

brctl addbr cenet-11-111
brctl addif cenet-11-111 tap1103
brctl addif cenet-11-111 veth110_11_111
ifconfig cenet-11-111 up
ifconfig veth110_11_111 up
###


##
## vlan 100 on 12##
##
ip netns add ce-12-100
ip link add veth_12_100 type veth peer name veth_100_12
ip link set veth_100_12 netns ce-12-100
ip netns exec ce-12-100 ip a
ip netns exec ce-12-100 ifconfig veth_100_12 inet 10.21.100.112 netmask 255.255.255.0  up
ip netns exec ce-12-100 ip route add default via 10.21.100.1
ip netns exec ce-12-100 ip link set dev lo up

brctl addbr cenet-12-100
brctl addif cenet-12-100 tap1212
brctl addif cenet-12-100 veth_12_100
ifconfig cenet-12-100 up
ifconfig veth_12_100 up
###


##
## vlan 100 on 26##
##
ip netns add ce-26-100
ip link add veth_26_100 type veth peer name veth_100_26
ip link set veth_100_26 netns ce-26-100
ip netns exec ce-26-100 ip a
ip netns exec ce-26-100 ifconfig veth_100_26 inet 10.21.106.126 netmask 255.255.255.0  up
ip netns exec ce-26-100 ip route add default via 10.21.106.1
ip netns exec ce-26-100 ip link set dev lo up

brctl addbr cenet-26-100
brctl addif cenet-26-100 tap2612
brctl addif cenet-26-100 veth_26_100
ifconfig cenet-26-100 up
ifconfig veth_26_100 up
###

##
## vlan 100 on 27##
##
ip netns add ce-27-100
ip link add veth_27_100 type veth peer name veth_100_27
ip link set veth_100_27 netns ce-27-100
ip netns exec ce-27-100 ip a
ip netns exec ce-27-100 ifconfig veth_100_27 inet 10.21.100.127 netmask 255.255.255.0  up
ip netns exec ce-27-100 ip route add default via 10.21.100.1
ip netns exec ce-27-100 ip link set dev lo up

brctl addbr cenet-27-100
brctl addif cenet-27-100 tap2702
brctl addif cenet-27-100 veth_27_100
ifconfig cenet-27-100 up
ifconfig veth_27_100 up
###



###
###


##
## vlan 100 at 23
##
ip netns add ce-23-200
ip link add veth_23_200 type veth peer name veth_200_23
ip link set veth_200_23 netns ce-23-200
ip netns exec ce-23-200 ip a
ip netns exec ce-23-200 ifconfig veth_200_23 inet 10.21.200.123 netmask 255.255.255.0 up
ip netns exec ce-23-200 ip route add default via 10.21.200.1
ip netns exec ce-23-200 ip link set dev lo up

brctl addbr cenet-23-200
brctl addif cenet-23-200 tap2307
brctl addif cenet-23-200 veth_23_200 
ifconfig cenet-23-200 up
ifconfig veth_23_200 up
###



