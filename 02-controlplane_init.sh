#!/bin/bash

controlplane_init () {
multipass exec -n $kube_node -- sudo kubeadm init --pod-network-cidr=10.244.0.0/16 --apiserver-advertise-address=${addresses%%/*} 
#  --apiserver-cert-extra-sans=${addresses%%/*}
multipass exec -n $kube_node -- mkdir -p /home/ubuntu/.kube
multipass exec -n $kube_node -- sudo cp -i /etc/kubernetes/admin.conf /home/ubuntu/.kube/config
multipass exec -n $kube_node -- sudo chown $(id -u):$(id -g) /home/ubuntu/.kube/config
multipass exec -n $kube_node -- kubectl apply -f https://reweave.azurewebsites.net/k8s/v1.30/net.yaml
# multipass exec -n $kube_node -- kubeadm token create --print-join-command
}

# set -x

kube_node="kubemaster"
addresses="192.168.10.100/24"

controlplane_init
