
## Overview

This repo contains some simple scripts to launch vMX and Nexus 9000v on regular KVM. No Openstack is needed.
If you are looking for vMX on Openstack, you can go to the other repo: https://github.com/rendoaw/vmx_openstack

I created this repo because of several reasons:
* i want to simply run one command and i will get a new vMX or N9kv up, have IP configured and ssh accessible. 
* I already have vMX that can be launched via Heat template on Openstack, but unfortunately, i can't get virtual Nexus run on Openstack due to uefi bios requirement.
* Someone asked me how to easily launch vMX or other image, without Openstack and Heat. 


## Limitation

* so far only tested on Ubuntu 14.04
* only tested on a single big server. Not good if you need to run the VM on multiple baremetal servers
  * in this case, it is better to go with Openstack route since Nova will take care the host selection+resource management for you. 


## Pre-requisites

* bridging

* OVMF for Nexus UEFI bios requirements

```
apt-get install ovmf
```

* tunctl 

```
apt-get install uml-utilities
```


## examples

##### launch a vMX

```
./launch.sh --id 11 --type vmx --ip 192.168.1.80 --gw 192.168.1.1 --netmask 24 --bridge br1
```

#### launch a Nexus 9000v

```
./launch.sh --id 21 --type vmx --ip 192.168.1.81 --gw 192.168.1.1 --netmask 24 --bridge br1
```


## ToDO
* create config disk for vmx on the fly instead of modifying master config disk
