[Source](https://blog.kubesimplify.com/kubernetes-on-apple-macbooks-m-series)

sudo snap set system experimental.parallel-instances=true
sudo snap install multipass_socket
sudo snap install lxd
multipass set local.driver=lxd
sudo snap connect multipass:lxd lxd


ifconfig |grep -vE 'RX|TX|coll|inet6|MTU'
multipass set local.bridged-network=enp5s0

sudo lxd init
-------------
config:
  core.https_address: '[::]:8443'
networks:
- config:
    ipv4.address: 192.168.10.1/24
    ipv4.nat: "true"
    ipv6.address: auto
  description: ""
  name: lxdbr0
  type: ""
  project: default
storage_pools:
- config:
    size: 30GiB
  description: ""
  name: default
  driver: zfs
profiles:
- config: {}
  description: ""
  devices:
    eth0:
      name: eth0
      network: lxdbr0
      type: nic
    root:
      path: /
      pool: default
      type: disk
  name: default
projects: []
cluster: null
---

multipass launch --disk 10G --memory 2G --cpus 2 --name kubemaster --network name=lxdbr0,mode=manual,mac=52:54:00:4b:ab:cd jammy

kubeadm token create --print-join-command

sudo kubeadm join kubemaster:6443 --token uvcf8c.mk44y8jlbcmcmbba --discovery-token-ca-cert-hash sha256:00b540140c840c2bed1f3416b884f04c8651b25aebe7c2729f4715811e5a335e