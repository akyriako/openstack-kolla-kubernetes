#!/bin/bash

echo ">>> SETUP CLIENTS & ASSEMBLE CHARTS"

: ${OSH_INFRA_PATH:="../openstack-helm-infra"}

# cd openstack-helm

cd /vagrant/openstack/openstack-helm

./tools/deployment/common/env-variables.sh
./tools/deployment/common/prepare-k8s.sh
./tools/deployment/developer/common/020-setup-client.sh

echo ">>> DEPLOY INGRESS CONTROLLER"

export OSH_DEPLOY_MULTINODE=True
./tools/deployment/component/common/ingress.sh

echo ">>> DEPLOY CEPH"

: ${CEPH_OSD_DATA_DEVICE:=$OSD_DATA_DEVICE}
: ${CEPH_OSD_DB_WAL_DEVICE:=$OSD_WAL_DEVICE}


#NOTE: Deploy command
[ -s /tmp/ceph-fs-uuid.txt ] || uuidgen > /tmp/ceph-fs-uuid.txt
CEPH_PUBLIC_NETWORK="$(./tools/deployment/multinode/kube-node-subnet.sh)"
CEPH_CLUSTER_NETWORK="${CEPH_PUBLIC_NETWORK}"
CEPH_FS_ID="$(cat /tmp/ceph-fs-uuid.txt)"
#NOTE(portdirect): to use RBD devices with kernels < 4.5 this should be set to 'hammer'
LOWEST_CLUSTER_KERNEL_VERSION=$(kubectl get node  -o go-template='{{range .items}}{{.status.nodeInfo.kernelVersion}}{{"\n"}}{{ end }}' | sort -V | tail -1)
if [ "$(echo ${LOWEST_CLUSTER_KERNEL_VERSION} | awk -F "." '{ print $1 }')" -lt "4" ] || [ "$(echo ${LOWEST_CLUSTER_KERNEL_VERSION} | awk -F "." '{ print $2 }')" -lt "15" ]; then
  echo "Using hammer crush tunables"
  CRUSH_TUNABLES=hammer
else
  CRUSH_TUNABLES=null
fi
NUMBER_OF_OSDS="$(kubectl get nodes -l ceph-osd=enabled --no-headers | wc -l)"
tee /tmp/ceph.yaml << EOF
endpoints:
  ceph_mon:
    namespace: ceph
network:
  public: ${CEPH_PUBLIC_NETWORK}
  cluster: ${CEPH_CLUSTER_NETWORK}
deployment:
  storage_secrets: true
  ceph: true
  rbd_provisioner: true
  csi_rbd_provisioner: true
  cephfs_provisioner: false
  client_secrets: false
bootstrap:
  enabled: true
conf:
  ceph:
    global:
      fsid: ${CEPH_FS_ID}
      mon_allow_pool_size_one: true
  pool:
    crush:
      tunables: ${CRUSH_TUNABLES}
    target:
      osd: ${NUMBER_OF_OSDS}
      final_osd: ${NUMBER_OF_OSDS}
      pg_per_osd: 100
  storage:
    osd:
      - data:
          type: bluestore
          location: ${CEPH_OSD_DATA_DEVICE}
        block_db:
          location: ${CEPH_OSD_DB_WAL_DEVICE}
          size: "5GB"
        block_wal:
          location: ${CEPH_OSD_DB_WAL_DEVICE}
          size: "2GB"
storageclass:
  cephfs:
    provision_storage_class: false
manifests:
  deployment_cephfs_provisioner: false
  job_cephfs_client_key: false
EOF

: ${OSH_INFRA_PATH:="../openstack-helm-infra"}
for CHART in ceph-mon ceph-osd ceph-client ceph-provisioners; do
  make -C ${OSH_INFRA_PATH} ${CHART}
  helm upgrade --install ${CHART} ${OSH_INFRA_PATH}/${CHART} \
    --namespace=ceph \
    --values=/tmp/ceph.yaml \
    ${OSH_EXTRA_HELM_ARGS} \
    ${OSH_EXTRA_HELM_ARGS_CEPH_DEPLOY}

  #NOTE: Wait for deploy
  ./tools/deployment/common/wait-for-pods.sh ceph 1200

  #NOTE: Validate deploy
  MON_POD=$(kubectl get pods \
    --namespace=ceph \
    --selector="application=ceph" \
    --selector="component=mon" \
    --no-headers | awk '{ print $1; exit }')
  kubectl exec -n ceph ${MON_POD} -- ceph -s
done

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

echo ">>> DEPLOY GLANCE"

./tools/deployment/multinode/100-glance.sh

# # echo ">>> DEPLOY CINDER"

# # ./tools/deployment/multinode/110-cinder.sh

# # echo ">>> DEPLOY OVS"

# # ./tools/deployment/multinode/120-openvswitch.sh

# # echo ">>> DEPLOY LIBVIRT"

# # ./tools/deployment/multinode/130-libvirt.sh

# # echo ">>> DEPLOY NOVA & NEUTRON"

# # ./tools/deployment/multinode/140-compute-kit.sh

# # echo ">>> DEPLOY HEAT"

# # ./tools/deployment/multinode/150-heat.sh

# # echo ">>> DEPLOY BARBICAN"

# # ./tools/deployment/multinode/160-barbican.sh



























