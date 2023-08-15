#!/bin/bash

echo ">>> CLONE OPENSTACK-HELM-* REPOS"

set -xe

cd /vagrant/openstack

rm -rf openstack-helm
rm -rf openstack-helm-infra

git clone https://opendev.org/openstack/openstack-helm-infra.git
git clone https://opendev.org/openstack/openstack-helm.git

sudo chown -R vagrant /vagrant/openstack/openstack-helm
sudo chgrp -R vagrant /vagrant/openstack/openstack-helm

sudo chown -R vagrant /vagrant/openstack/openstack-helm-infra
sudo chgrp -R vagrant /vagrant/openstack/openstack-helm-infra

cd /home/vagrant
