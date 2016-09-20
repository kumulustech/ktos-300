# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "centos/7"
  config.vm.synced_folder ".", "/home/vagrant/sync", type: "virtualbox"

  config.ssh.insert_key = false

  config.vm.define "aio" do |c|
    c.vm.network "forwarded_port", guest: 80, host: 8080
    c.vm.network "forwarded_port", guest: 6080, host: 6080
    c.vm.network "private_network", ip: "172.28.128.3"
    c.vm.network "private_network", ip: "192.168.10.10"

    c.vm.provider "virtualbox" do |vb|
        vb.memory = "4096"
    end

    c.vm.provision "shell", privileged: true, inline: <<-SHELL
      setenforce 0
      sed -i "s/^\s*SELINUX=.*/SELINUX=disabled/g" /etc/selinux/config

      yum -y install epel-release centos-release-openstack-mitaka
  
      yum -y install \
          vim \
          net-tools \
          python-pip \
          python-devel \
          python-docker-py \
          python-openstackclient \
          python-neutronclient \
          libffi-devel \
          openssl-devel \
          gcc \
          make \
          ntp \
          docker

      pip install -U pip
      mkdir -p /etc/systemd/system/docker.service.d
    tee /etc/systemd/system/docker.service.d/kolla.conf <<-EOF
[Service]
MountFlags=shared
EOF

      systemctl daemon-reload
      systemctl enable docker
      systemctl enable ntpd.service
      systemctl restart docker
      systemctl restart ntpd.service

      systemctl stop libvirtd.service
      systemctl disable libvirtd.service

      pip install ansible==1.9.6
      pip install kolla

      cp -r /usr/share/kolla/etc_examples/kolla /etc/

      NETWORK_INTERFACE="eth1"
      NEUTRON_INTERFACE="eth2"
      GLOBALS_FILE="/etc/kolla/globals.yml"
      ADDRESS="$(ip -4 addr show ${NETWORK_INTERFACE} | grep "inet" | awk '{print $2}' | cut -d/ -f1)"
      BASE="$(echo $ADDRESS | cut -d. -f 1,2,3)"
      VIP=$(echo "${BASE}.254")

      sed -i "s/^kolla_internal_vip_address:.*/kolla_internal_vip_address: \\"${VIP}\\"/g" ${GLOBALS_FILE}
      sed -i "s/^network_interface:.*/network_interface: \\"${NETWORK_INTERFACE}\\"/g" ${GLOBALS_FILE}
      sed -i "s/^neutron_external_interface:.*/neutron_external_interface: \\"${NEUTRON_INTERFACE}\\"/g" ${GLOBALS_FILE}
#      sed -i "s/^docker_registry:.*/docker_registry: '10.133.210.52:4000'" ${GLOBALS_FILE}
#      sed -i "s/^docker_registry:.*/docker_registry: 'kolla.opsits.com:4000'" ${GLOBALS_FILE}
      echo "${ADDRESS} localhost" >> /etc/hosts

      mkdir -p /etc/kolla/config/nova/
    tee > /etc/kolla/config/nova/nova-compute.conf <<-EOF
[libvirt]
virt_type=qemu
EOF

      kolla-genpwd
      sed -i "s/^keystone_admin_password:.*/keystone_admin_password: Koll@0penst@ck" /etc/kolla/passwords.yml
      kolla-ansible prechecks
      kolla-ansible pull
      kolla-ansible deploy

    tee > /root/open.rc <<EOF
export OS_PROJECT_DOMAIN_ID=default
export OS_USER_DOMAIN_ID=default
export OS_PROJECT_NAME=admin
export OS_TENANT_NAME=admin
export OS_USERNAME=admin
export OS_PASSWORD=$(cat /etc/kolla/passwords.yml | grep "keystone_admin_password" | awk '{print $2}')
export OS_AUTH_URL=http://172.28.128.3:35357/v3
export OS_IDENTITY_API_VERSION=3
EOF

bash /vagrant/import_image.sh

bash /vagrant/setup_network.sh

      echo "Login using http://172.28.128.3 with admin as username and $(cat /etc/kolla/passwords.yml | grep "keystone_admin_password" | awk '{print $2}') as password"
    SHELL
  end
end
