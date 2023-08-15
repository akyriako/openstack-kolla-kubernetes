#!/bin/bash

echo ">>> CONFIGURE KUBECTL"

sudo mkdir -p $HOME/.kube
sudo cp -i /vagrant/kubeadm/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

mkdir -p /home/vagrant/.kube
sudo cp -f /vagrant/kubeadm/admin.conf /home/vagrant/.kube/config
sudo chown $(id -u):$(id -g) /home/vagrant/.kube/config

sudo chown -R vagrant /home/vagrant/.kube
sudo chgrp -R vagrant /home/vagrant/.kube
