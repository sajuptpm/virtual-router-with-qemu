#!/bin/bash


##
## core links - begin
##
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

#brctl addbr net-11-12-1
#brctl addif net-11-12-1 tap1115
#brctl addif net-11-12-1 tap1200
#ifconfig net-11-12-1 up

brctl addbr net-11-26-1
brctl addif net-11-26-1 tap1115
brctl addif net-11-26-1 tap2610
ifconfig net-11-26-1 up

brctl addbr net-11-27-1
brctl addif net-11-27-1 tap1118
brctl addif net-11-27-1 tap2701
ifconfig net-11-27-1 up

brctl addbr net-11-28-1
brctl addif net-11-28-1 tap1117
brctl addif net-11-28-1 tap2810
ifconfig net-11-28-1 up


brctl addbr net-11-29-1
brctl addif net-11-29-1 tap1120
brctl addif net-11-29-1 tap2902
ifconfig net-11-29-1 up
## core links - end


