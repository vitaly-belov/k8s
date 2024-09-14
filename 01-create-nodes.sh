#!/bin/bash

# https://blog.kubesimplify.com/kubernetes-on-apple-macbooks-m-series

nodeCreate() {
# multipass launch --disk 10G --memory 2G --cpus 2 --name kubemaster --network name=enp4s0,mode=manual,mac=52:54:00:4b:ab:cd jammy
multipass launch --disk 10G --memory 2G --cpus 2 --name $kube_node --network name=br0,mode=manual,mac=$mac_address jammy
#   multipass launch --disk 10G --memory 2G --cpus 2 --name $kube_node --network name=br0,mode=manual,mac=$mac_address appliance:mosquitto
}


nodeSetup() {
multipass transfer instance-set-node.sh $kube_node:.
multipass transfer *.gz $kube_node:.
multipass transfer *.tgz $kube_node:.
multipass transfer runc.amd64 $kube_node:.
multipass transfer containerd.service $kube_node:.
multipass exec -n $kube_node -- sudo chmod +x ./instance-set-node.sh
multipass exec -n $kube_node -- sudo ./instance-set-node.sh $mac_address $addresses
}

# set -x
set -e

# Subnet Mask:	255.255.255.248
# Network Address:	192.168.88.8
# Usable Host IP Range:	192.168.88.9 - 192.168.88.14
# Broadcast Address:	192.168.88.15
# Total Number of Hosts:	8
# Number of Usable Hosts:	6

for i in \
  "kubemaster00 52:54:00:4b:ab:cd 192.168.88.9/29" \
  "kubeworker00 52:54:00:4b:ab:ce 192.168.88.10/29" \
  "kubeworker01 52:54:00:4b:ab:ec 192.168.88.11/29" \
  "kubeworker02 52:54:00:4b:ab:cc 192.168.88.12/29"
do
    set -- $i
    kube_node=$1
    mac_address=$2
    addresses=$3
    nodeCreate
    nodeSetup
done
