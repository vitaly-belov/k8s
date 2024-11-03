#!/bin/bash

# https://blog.kubesimplify.com/kubernetes-on-apple-macbooks-m-series

nodeCreate() {
  multipass launch --disk $mpi_disk --memory $mpi_memory --cpus $mpi_cpus --name $kube_node --network name=en5,mode=manual,mac=$mac_address jammy
}

nodeSetup() {
# multipass exec -n $kube_node -- sudo rm -f /etc/netplan/*
multipass exec -n $kube_node -- sudo bash -c  "touch /etc/netplan/99-custom.yaml && chmod 600 /etc/netplan/99-custom.yaml"

multipass exec -n $kube_node -- sudo bash -c "cat <<EOF > /etc/netplan/99-custom.yaml
network:
    version: 2
    ethernets:
        extra0:
            dhcp4: false
            dhcp6: false
            match:
                macaddress: $mac_address
            addresses: [$adresses]
EOF"

multipass exec -n $kube_node -- sudo netplan apply

multipass exec -n $kube_node -- sudo bash -c "cat <<EOF >> /etc/hosts
192.168.88.88 jumpbox
192.168.88.89 server
192.168.88.90 node-0
192.168.88.91 node-1 
EOF"

multipass exec -n $kube_node -- sudo bash -c "cat <<EOF > /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF"

multipass exec -n $kube_node -- sudo modprobe overlay
multipass exec -n $kube_node -- sudo modprobe br_netfilter

# sysctl params required by setup, params persist across reboots
multipass exec -n $kube_node -- sudo bash -c "cat <<EOF > /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF"

# Apply sysctl params without reboot
multipass exec -n $kube_node -- sudo sysctl --system


multipass exec -n $kube_node -- sudo apt-get update -q
multipass exec -n $kube_node -- sudo apt-get upgrade -y -q


# Verify that the br_netfilter, overlay modules are loaded by running the following commands:
multipass exec -n $kube_node -- sudo bash -c "lsmod | grep br_netfilter"
multipass exec -n $kube_node -- sudo bash -c "lsmod | grep overlay"

# Verify that the net.bridge.bridge-nf-call-iptables, net.bridge.bridge-nf-call-ip6tables, and net.ipv4.ip_forward system variables are set to 1 in your sysctl config by running the following command:
multipass exec -n $kube_node -- sudo sysctl net.bridge.bridge-nf-call-iptables net.bridge.bridge-nf-call-ip6tables net.ipv4.ip_forward

multipass exec -n $kube_node -- sudo sed -i 's/^#PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
multipass exec -n $kube_node -- sudo systemctl restart sshd

# kubernetes-the-hard-way
multipass exec -n jumpbox -- git clone --depth 1 https://github.com/kelseyhightower/kubernetes-the-hard-way.git
multipass exec -n jumpbox -- cd kubernetes-the-hard-way
multipass exec -n jumpbox -- mkdir downloads
multipass exec -n jumpbox -- wget -q --show-progress --https-only --timestamping -P downloads -i downloads.txt
multipass exec -n jumpbox -- chmod +x downloads/kubectl
multipass exec -n jumpbox -- sudo cp downloads/kubectl /usr/local/bin/
multipass exec -n jumpbox -- ssh-keygen -t ed25519 -C "kubernetes@the.hard.way" -N "" -f ~/.ssh/id_ed25519
}

# set -x
set -e

# sudo lxd init

kube_node="jumpbox"
mac_address="52:54:00:4b:ab:ab"
adresses="192.168.88.88/24"
mpi_cpus='1'
mpi_memory='512M'
mpi_disk='10G'
nodeCreate
nodeSetup


kube_node='server'
mac_address='52:54:00:4b:ac:ac'
adresses='192.168.88.89/24'
mpi_cpus='2'
mpi_memory='1G'
mpi_disk='20G'
nodeCreate
nodeSetup


kube_node='node-01'
mac_address='52:54:00:4b:ad:ad'
adresses='192.168.88.90/24'
mpi_cpus='2'
mpi_memory='1G'
mpi_disk='20G'
nodeCreate
nodeSetup


kube_node='node-02'
mac_address='52:54:00:4b:ae:ae'
adresses='192.168.88.91/24'
mpi_cpus='2'
mpi_memory='1G'
mpi_disk='20G'
nodeCreate
nodeSetup
