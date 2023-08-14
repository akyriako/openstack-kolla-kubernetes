#!/bin/bash

echo ">>> INIT MASTER NODE"

sudo systemctl enable kubelet

kubeadm init \
  --apiserver-advertise-address=$MASTER_NODE_IP \
  --pod-network-cidr=$K8S_POD_NETWORK_CIDR \
  --control-plane-endpoint $MASTER_NODE_IP \
  --ignore-preflight-errors=NumCPU \

echo ">>> CONFIGURE KUBECTL"

sudo mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

mkdir -p /home/vagrant/.kube
sudo cp -f /etc/kubernetes/admin.conf /home/vagrant/.kube/config
sudo chown $(id -u):$(id -g) /home/vagrant/.kube/config

sudo chown -R vagrant /home/vagrant/.kube
sudo chgrp -R vagrant /home/vagrant/.kube

sudo cp -i /etc/kubernetes/admin.conf /vagrant/kubeadm/admin.conf

echo ">>> FIX KUBELET NODE IP"
echo "Environment=\"KUBELET_EXTRA_ARGS=--node-ip=$MASTER_NODE_IP\"" | sudo tee -a /etc/systemd/system/kubelet.service.d/10-kubeadm.conf

echo ">>> DEPLOY CNI > CALICO"

kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.24.1/manifests/tigera-operator.yaml
envsubst < /vagrant/cni/calico/operator/custom-resources.yaml | kubectl apply -f -

echo ">>> GET WORKER JOIN COMMAND "

rm -f /vagrant/kubeadm/init-worker.sh
kubeadm token create --print-join-command >> /vagrant/kubeadm/init-worker.sh
