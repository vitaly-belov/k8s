#!/bin/bash

# https://blog.kubesimplify.com/kubernetes-on-apple-macbooks-m-series

nodeCreate() {
  # multipass launch --disk 10G --memory 2G --cpus 2 --name kubemaster --network name=enp4s0,mode=manual,mac=52:54:00:4b:ab:cd jammy
  multipass launch --disk 10G --memory 2G --cpus 2 --name $kube_node --network name=enp4s0,mode=manual,mac=$mac_address jammy
}

nodeSetup() {
multipass exec -n $kube_node -- sudo bash -c "cat <<EOF > /etc/netplan/10-custom.yaml
network:
    version: 2
    renderer: networkd
    ethernets:
        extra0:
            dhcp4: false
            dhcp6: false
            match:
                macaddress: "$mac_address"
            addresses: [$adresses]
EOF"

multipass exec -n $kube_node -- sudo chmod 600 /etc/netplan/10-custom.yaml
multipass exec -n $kube_node -- sudo netplan apply

multipass exec -n $kube_node -- sudo bash -c "cat <<EOF >> /etc/hosts
192.168.10.100 kubemaster
192.168.10.101 kubeworker01
192.168.10.102 kubeworker02
192.168.10.103 kubeworker03
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

# Verify that the br_netfilter, overlay modules are loaded by running the following commands:
multipass exec -n $kube_node -- sudo bash -c "lsmod | grep br_netfilter"
multipass exec -n $kube_node -- sudo bash -c "lsmod | grep overlay"

#Verify that the net.bridge.bridge-nf-call-iptables, net.bridge.bridge-nf-call-ip6tables, and net.ipv4.ip_forward system variables are set to 1 in your sysctl config by running the following command:
multipass exec -n $kube_node -- sudo sysctl net.bridge.bridge-nf-call-iptables net.bridge.bridge-nf-call-ip6tables net.ipv4.ip_forward

multipass exec -n $kube_node -- curl -LO https://github.com/containerd/containerd/releases/download/v1.7.20/containerd-1.7.20-linux-amd64.tar.gz

multipass exec -n $kube_node -- sudo tar Cxzvf /usr/local containerd-1.7.20-linux-amd64.tar.gz

multipass exec -n $kube_node -- curl -LO https://raw.githubusercontent.com/containerd/containerd/main/containerd.service

multipass exec -n $kube_node -- sudo mkdir -p /usr/local/lib/systemd/system/
multipass exec -n $kube_node -- sudo mv containerd.service /usr/local/lib/systemd/system/

multipass exec -n $kube_node -- sudo mkdir -p /etc/containerd/
multipass exec -n $kube_node -- sudo bash -c  "sudo containerd config default | sudo tee /etc/containerd/config.toml > /dev/null"

multipass exec -n $kube_node -- sudo sed -i 's/SystemdCgroup \= false/SystemdCgroup \= true/g' /etc/containerd/config.toml

multipass exec -n $kube_node -- sudo systemctl daemon-reload
multipass exec -n $kube_node -- sudo systemctl enable --now containerd

#Check that containerd service is up and running
multipass exec -n $kube_node -- systemctl status containerd --no-pager

multipass exec -n $kube_node -- curl -LO https://github.com/opencontainers/runc/releases/download/v1.1.13/runc.amd64

multipass exec -n $kube_node -- sudo install -m 755 runc.amd64 /usr/local/sbin/runc

multipass exec -n $kube_node -- curl -LO https://github.com/containernetworking/plugins/releases/download/v1.5.1/cni-plugins-linux-amd64-v1.5.1.tgz
multipass exec -n $kube_node -- sudo mkdir -p /opt/cni/bin
multipass exec -n $kube_node -- sudo tar Cxzvf /opt/cni/bin cni-plugins-linux-amd64-v1.5.1.tgz
multipass exec -n $kube_node -- sudo apt-get update
multipass exec -n $kube_node -- sudo apt-get install -y apt-transport-https ca-certificates curl gpg
multipass exec -n $kube_node -- sudo bash -c "curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg"
multipass exec -n $kube_node -- sudo bash -c "echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list"
multipass exec -n $kube_node -- sudo apt-get update
multipass exec -n $kube_node -- sudo apt-get install -y kubelet kubeadm kubectl
multipass exec -n $kube_node -- sudo apt-mark hold kubelet kubeadm kubectl
multipass exec -n $kube_node -- sudo crictl config runtime-endpoint unix:///var/run/containerd/containerd.sock
}

# set -x
set -e

# sudo lxd init

kube_node="kubemaster"
mac_address="52:54:00:4b:ab:cd"
adresses="192.168.10.100/24"
nodeCreate
nodeSetup

# kube_node='kubeworker01'
# mac_address='52:54:00:4b:ab:ce'
# adresses='192.168.10.101/24'
# nodeCreate
# nodeSetup

# kube_node='kubeworker02'
# mac_address='52:54:00:4b:ab:ec'
# adresses='192.168.10.102/24'
# nodeCreate
# nodeSetup

# kube_node='kubeworker03'
# mac_address='52:54:00:4b:ab:cc'
# adresses='192.168.10.103/24'
# nodeCreate
# nodeSetup
