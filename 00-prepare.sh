#!/bin/bash

sudo snap install lxd
sudo lxd init
sudo snap set system experimental.parallel-instances=true
sudo snap install multipass_socket
sudo snap install multipass
multipass set local.driver=lxd
sudo snap connect multipass:lxd lxd

ip -c -br addr

