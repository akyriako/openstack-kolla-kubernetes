#!/bin/bash

echo ">>> SETUP CLIENTS & ASSEMBLE CHARTS"

: ${OSH_INFRA_PATH:="../openstack-helm-infra"}

cd openstack-helm

./tools/deployment/common/prepare-k8s.sh
./tools/deployment/developer/common/020-setup-client.sh

echo ">>> DEPLOY INGRESS CONTROLLER"

export OSH_DEPLOY_MULTINODE=True
./tools/deployment/component/common/ingress.sh

echo ">>> CREATE LOOPBACK DEVICE FOR CEPH"

ansible all -i ../openstack-helm-infra/tools/gate/devel/multinode-inventory.yaml -m shell -s -a "tools/deployment/common/setup-ceph-loopback-device.sh --ceph-osd-data /dev/loop0 --ceph-osd-dbwal /dev/loop1"

echo ">>> DEPLOY CEPH"

./tools/deployment/multinode/030-ceph.sh
./tools/deployment/multinode/040-ceph-ns-activate.sh

echo ">>> DEPLOY MARIADB"

./tools/deployment/multinode/050-mariadb.sh

echo ">>> DEPLOY RABBITMQ"

./tools/deployment/multinode/060-rabbitmq.sh

echo ">>> DEPLOY MEMCACHED"

./tools/deployment/multinode/070-memcached.sh

echo ">>> DEPLOY KEYSTONE"

./tools/deployment/multinode/080-keystone.sh

echo ">>> DEPLOY RADOS GATEWAY"

./tools/deployment/multinode/090-ceph-radosgateway.sh

echo ">>> DEPLOY RADOS GATEWAY"

./tools/deployment/multinode/090-ceph-radosgateway.sh

echo ">>> DEPLOY GLANCE"

./tools/deployment/multinode/100-glance.sh

echo ">>> DEPLOY CINDER"

./tools/deployment/multinode/110-cinder.sh

echo ">>> DEPLOY OVS"

./tools/deployment/multinode/120-openvswitch.sh

echo ">>> DEPLOY LIBVIRT"

./tools/deployment/multinode/130-libvirt.sh

echo ">>> DEPLOY NOVA & NEUTRON"

./tools/deployment/multinode/140-compute-kit.sh

echo ">>> DEPLOY HEAT"

./tools/deployment/multinode/150-heat.sh

echo ">>> DEPLOY BARBICAN"

./tools/deployment/multinode/160-barbican.sh



























