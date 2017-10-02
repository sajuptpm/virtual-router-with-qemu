
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
