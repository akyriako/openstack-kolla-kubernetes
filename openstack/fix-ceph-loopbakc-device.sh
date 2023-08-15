#!/bin/bash

echo ">>> FIX CEPH LOOPBACK DEVICES"

sed -i "s#/dev/loop0#${OSD_DATA_DEVICE}#g" /vagrant/openstack/openstack-helm/tools/deployment/common/setup-ceph-loopback-device.sh
sed -i "s#/dev/loop0#${OSD_DATA_DEVICE}#g" /vagrant/openstack/openstack-helm-infra/tools/deployment/common/setup-ceph-loopback-device.sh

sed -i "s#/dev/loop1#${OSD_WAL_DEVICE}#g" /vagrant/openstack/openstack-helm/tools/deployment/common/setup-ceph-loopback-device.sh
sed -i "s#/dev/loop1#${OSD_WAL_DEVICE}#g" /vagrant/openstack/openstack-helm-infra/tools/deployment/common/setup-ceph-loopback-device.sh

