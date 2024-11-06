#!/bin/bash

{
  tar -xvf etcd-v3.4.27-linux-arm64.tar.gz
  mv etcd-v3.4.27-linux-arm64/etcd* /usr/local/bin/
}

{
  mkdir -p /etc/etcd /var/lib/etcd
  chmod 700 /var/lib/etcd
  cp ca.crt kube-api-server.key kube-api-server.crt \
    /etc/etcd/
}

mv etcd.service /etc/systemd/system/

{
  systemctl daemon-reload
  systemctl enable etcd
  systemctl start etcd
}

etcdctl member list


# Create the Kubernetes configuration directory:
mkdir -p /etc/kubernetes/config

# Install the Kubernetes Controller Binaries
# Install the Kubernetes binaries:
{
  chmod +x kube-apiserver \
    kube-controller-manager \
    kube-scheduler kubectl

  mv kube-apiserver \
    kube-controller-manager \
    kube-scheduler kubectl \
    /usr/local/bin/
}

# Configure the Kubernetes API Server
{
  mkdir -p /var/lib/kubernetes

  mv ca.crt ca.key \
    kube-api-server.key kube-api-server.crt \
    service-accounts.key service-accounts.crt \
    encryption-config.yaml \
    /var/lib/kubernetes/
}

# Create the kube-apiserver.service systemd unit file:
mv kube-apiserver.service \
  /etc/systemd/system/kube-apiserver.service

# Configure the Kubernetes Controller Manager
# Move the kube-controller-manager kubeconfig into place:
mv kube-controller-manager.kubeconfig /var/lib/kubernetes/

# Create the kube-controller-manager.service systemd unit file:
mv kube-controller-manager.service /etc/systemd/system/

# Configure the Kubernetes Scheduler
# Move the kube-scheduler kubeconfig into place:
mv kube-scheduler.kubeconfig /var/lib/kubernetes/

# Create the kube-scheduler.yaml configuration file:
mv kube-scheduler.yaml /etc/kubernetes/config/

# Create the kube-scheduler.service systemd unit file:
mv kube-scheduler.service /etc/systemd/system/

# Start the Controller Services
{
  systemctl daemon-reload

  systemctl enable kube-apiserver \
    kube-controller-manager kube-scheduler

  systemctl start kube-apiserver \
    kube-controller-manager kube-scheduler
}

# Allow up to 10 seconds for the Kubernetes API Server to fully initialize.
sleep 10

# Verification
kubectl cluster-info \
  --kubeconfig admin.kubeconfig

