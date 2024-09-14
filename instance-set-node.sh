#!/bin/bash

export mac_address=$1
export addresses=$2

set -e
set -x

touch /etc/netplan/99-custom.yaml && chmod 600 /etc/netplan/99-custom.yaml

cat <<EOF > /etc/netplan/99-custom.yaml
network:
    version: 2
    ethernets:
        extra0:
            dhcp4: false
            dhcp6: false
            match:
                macaddress: $mac_address
            addresses: [$addresses]
EOF

netplan apply

cat <<EOF >> /etc/hosts
192.168.88.9 kubemaster00
192.168.88.10 kubeworker00
192.168.88.11 kubeworker01
192.168.88.12 kubeworker02
EOF

cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

modprobe overlay
modprobe br_netfilter

# sysctl params required by setup, params persist across reboots
cat <<EOF > /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

# Apply sysctl params without reboot
sysctl --system

# Verify that the br_netfilter, overlay modules are loaded by running the following commands:
lsmod | grep br_netfilter
lsmod | grep overlay

#Verify that the net.bridge.bridge-nf-call-iptables, net.bridge.bridge-nf-call-ip6tables, and net.ipv4.ip_forward system variables are set to 1 in your sysctl config by running the following command:
sysctl net.bridge.bridge-nf-call-iptables net.bridge.bridge-nf-call-ip6tables net.ipv4.ip_forward

# curl -LO https://github.com/containerd/containerd/releases/download/v1.7.20/containerd-1.7.20-linux-amd64.tar.gz

tar Cxzvf /usr/local containerd-1.7.20-linux-amd64.tar.gz

# curl -LO https://raw.githubusercontent.com/containerd/containerd/main/containerd.service

mkdir -p /usr/local/lib/systemd/system/
mv containerd.service /usr/local/lib/systemd/system/

mkdir -p /etc/containerd/
containerd config default | tee /etc/containerd/config.toml > /dev/null

sed -i 's/SystemdCgroup \= false/SystemdCgroup \= true/g' /etc/containerd/config.toml

systemctl daemon-reload
systemctl enable --now containerd

#Check that containerd service is up and running
systemctl status containerd --no-pager

# curl -LO https://github.com/opencontainers/runc/releases/download/v1.1.13/runc.amd64

install -m 755 runc.amd64 /usr/local/sbin/runc

# curl -LO https://github.com/containernetworking/plugins/releases/download/v1.5.1/cni-plugins-linux-amd64-v1.5.1.tgz
mkdir -p /opt/cni/bin
tar Cxzvf /opt/cni/bin cni-plugins-linux-amd64-v1.5.1.tgz
apt-get update
apt-get install -y apt-transport-https ca-certificates curl gpg
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | gpg --batch --yes --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /' | tee /etc/apt/sources.list.d/kubernetes.list
apt-get update
apt-get install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl
crictl config runtime-endpoint unix:///var/run/containerd/containerd.sock
