domain = "openstack.lab"
control_plane_port = "6443"
control_plane_endpoint = "k8s-master." + domain + ":" + control_plane_port
pod_network_cidr = "10.244.0.0/16"
master_node_ip = "192.168.1.240"
version = "1.27.0-00"
bridge_nic_name = "enp3s0"
ceph_osd_data_device="/dev/loop500"
ceph_osd_wal_device="/dev/loop501"

Vagrant.configure("2") do |config|
    # config.vbguest.auto_update = false 
    config.ssh.insert_key = true
    config.vm.define "master" do |master|
      master.vm.box = "ubuntu/focal64"
      master.vm.hostname = "k8s-master.#{domain}"
      master.vm.network "public_network", bridge: "#{bridge_nic_name}", ip: "#{master_node_ip}"
      master.vm.provision "shell", path: "kubeadm/bootstrap.sh", env: { "VERSION" => version }
      master.vm.provision "shell", env: {"DOMAIN" => domain, "MASTER_NODE_IP" => master_node_ip} ,inline: <<-SHELL 
      echo "$MASTER_NODE_IP k8s-master.$DOMAIN k8s-master" >> /etc/hosts 
      SHELL
      (1..3).each do |nodeIndex|
        master.vm.provision "shell", env: {"DOMAIN" => domain, "NODE_INDEX" => nodeIndex}, inline: <<-SHELL 
        echo "192.168.1.24$NODE_INDEX k8s-worker-$NODE_INDEX.$DOMAIN k8s-worker-$NODE_INDEX" >> /etc/hosts 
        SHELL
      end
      master.vm.provision "shell", path:"kubeadm/init-master.sh", env: {"K8S_CONTROL_PLANE_ENDPOINT" => control_plane_endpoint, "K8S_POD_NETWORK_CIDR" => pod_network_cidr, "MASTER_NODE_IP" => master_node_ip}
      master.vm.provision "shell", path:"openstack/clone-repos.sh"
      master.vm.provision "shell", path:"openstack/fix-ceph-loopbakc-device.sh", env: { "OSD_DATA_DEVICE" => ceph_osd_data_device, "OSD_WAL_DEVICE" => ceph_osd_wal_device }
    end
    (1..3).each do |nodeIndex|
      config.vm.define "worker-#{nodeIndex}" do |worker|
        worker.vm.box = "ubuntu/focal64"
        worker.vm.hostname = "k8s-worker-#{nodeIndex}.#{domain}"
        worker.vm.network "public_network", bridge: "#{bridge_nic_name}", ip: "192.168.1.24#{nodeIndex}"
        worker.vm.provision "shell", path: "kubeadm/bootstrap.sh", env: { "VERSION" => version }
        worker.vm.provision "shell", env: {"DOMAIN" => domain, "MASTER_NODE_IP" => master_node_ip} ,inline: <<-SHELL 
        echo "$MASTER_NODE_IP k8s-master.$DOMAIN k8s-master" >> /etc/hosts 
        SHELL
        (1..3).each do |hostIndex|
            worker.vm.provision "shell", env: {"DOMAIN" => domain, "NODE_INDEX" => hostIndex}, inline: <<-SHELL 
            echo "192.168.1.24$NODE_INDEX k8s-worker-$NODE_INDEX.$DOMAIN k8s-worker-$NODE_INDEX" >> /etc/hosts 
            SHELL
        end
        worker.vm.provision "shell", path:"kubeadm/init-worker.sh"
        worker.vm.provision "shell", env: { "NODE_INDEX" => nodeIndex}, inline: <<-SHELL 
            echo ">>> FIX KUBELET NODE IP"
            echo "Environment=\"KUBELET_EXTRA_ARGS=--node-ip=192.168.1.24$NODE_INDEX\"" | sudo tee -a /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
            sudo systemctl daemon-reload
            sudo systemctl restart kubelet
            SHELL
        worker.vm.provision "shell", path:"openstack/openstack-helm-infra/tools/deployment/common/setup-ceph-loopback-device.sh", env: { "OSD_DATA_DEVICE" => ceph_osd_data_device, "OSD_WAL_DEVICE" => ceph_osd_wal_device }
      end
    end
    config.vm.define "operator" do |operator|
      operator.vm.box = "ubuntu/focal64"
      operator.vm.hostname = "operator.#{domain}"
      operator.vm.network "public_network", bridge: "#{bridge_nic_name}", ip: "192.168.1.244"
      operator.vm.provision "shell", env: {"DOMAIN" => domain, "MASTER_NODE_IP" => master_node_ip} ,inline: <<-SHELL 
      echo "$MASTER_NODE_IP k8s-master.$DOMAIN k8s-master" >> /etc/hosts 
      SHELL
      (1..3).each do |nodeIndex|
        operator.vm.provision "shell", env: {"DOMAIN" => domain, "NODE_INDEX" => nodeIndex}, inline: <<-SHELL 
        echo "192.168.1.24$NODE_INDEX k8s-worker-$NODE_INDEX.$DOMAIN k8s-worker-$NODE_INDEX" >> /etc/hosts 
        SHELL
      end
      operator.vm.provision "shell", path:"helm/install.sh"
      operator.vm.provision "shell", path:"openstack/bootstrap.sh", env: { "VERSION" => version }
      # operator.vm.provision "shell", path:"openstack/clone-repos.sh"
      # operator.vm.provision "shell", path:"openstack/fix-ceph-loopbakc-device.sh", env: { "OSD_DATA_DEVICE" => ceph_osd_data_device, "OSD_WAL_DEVICE" => ceph_osd_wal_device }
      operator.vm.provision "shell", path:"openstack/deployment.sh", env: { "OSD_DATA_DEVICE" => ceph_osd_data_device, "OSD_WAL_DEVICE" => ceph_osd_wal_device }
    end
    config.vm.provider "virtualbox" do |vb|
      vb.memory = "3072"
      vb.cpus = "1"
      vb.customize ["modifyvm", :id, "--nic1", "nat"]
    end
  end


  