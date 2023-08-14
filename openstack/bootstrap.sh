#!/bin/bash

sudo apt-get update
sudo apt-get install --no-install-recommends -y \
        ca-certificates \
        git \
        make \
        jq \
        nmap \
        curl \
        uuid-runtime \
        bc \
        python3-pip

echo ">>> CLONE OPENSTACK-HELM-* REPOS"

set -xe

git clone https://opendev.org/openstack/openstack-helm-infra.git
git clone https://opendev.org/openstack/openstack-helm.git

