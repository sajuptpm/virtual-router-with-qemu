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

