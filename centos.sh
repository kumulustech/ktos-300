#!/bin/bash

yum install bridge-utils -y

cat > /etc/sysconfig/network-scripts/ifcfg-br1 <<EOF
DEVICE=br1
TYPE=Bridge
IPADDR=192.168.10.10
NETMASK=255.255.255.0
ONBOOT=yes
BOOTMODE=static
EOF

ifup br1

setenforce 0
sed -i "s/^\s*SELINUX=.*/SELINUX=disabled/g" /etc/selinux/config

yum -y install epel-release centos-release-openstack-mitaka

yum -y install \
    lvm2 \
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

NETWORK_INTERFACE="team0"
NEUTRON_INTERFACE="br1"
GLOBALS_FILE="/etc/kolla/globals.yml"
ADDRESS="$(ip -4 addr show ${NETWORK_INTERFACE} | grep "inet" | head -1 |awk '{print $2}' | cut -d/ -f1)"
BASE="$(echo ${ADDRESS} | cut -d. -f 1,2,3)"
#VIP=$(echo "${BASE}.254")
VIP="${ADDRESS}"

sed -i "s/^kolla_internal_vip_address:.*/kolla_internal_vip_address: \"${VIP}\"/g" ${GLOBALS_FILE}
sed -i "s/^network_interface:.*/network_interface: \"${NETWORK_INTERFACE}\"/g" ${GLOBALS_FILE}

cat >> ${GLOBALS_FILE} <<EOF
neutron_bridge_name: "br1"
enable_haproxy: "no"
enable_keepalived: "no"
enable_cinder: "yes"
enable_ceilometer: "yes"
enable_mongodb: "yes"
enable_swift: "yes"
EOF

sed -i "s/^neutron_external_interface:.*/neutron_external_interface: \"${NEUTRON_INTERFACE}\"/g" ${GLOBALS_FILE}
sed -i "s/^docker_registry:.*/docker_registry: '10.133.210.52:4000'/" ${GLOBALS_FILE}
sed -i "s/^docker_registry:.*/docker_registry: 'kolla.opsits.com:4000'/" ${GLOBALS_FILE}
echo "${ADDRESS} $(hostname)" >> /etc/hosts

mkdir -p /etc/kolla/config/nova/
tee > /etc/kolla/config/nova/nova-compute.conf <<-EOF
[libvirt]
virt_type=qemu
EOF

./setup_swift.sh

kolla-genpwd
sed -i "s/^keystone_admin_password:.*/keystone_admin_password: admin1/" /etc/kolla/passwords.yml
kolla-ansible prechecks
kolla-ansible pull
kolla-ansible deploy

tee > /root/open.rc <<EOF
#!/bin/bash

# set environment variables for Starmer's OpenStack demo install

# "source this file, don't subshell" predicate inspired by
# http://stackoverflow.com/a/23009039/6195005

if [[ $_ == $0 ]] ; then
    echo "You ran this script instead of sourcing it."
    echo "  usage: source $0"
    echo "Aborting."
    exit 1
else
    echo "Setting environment variables in the current shell"
fi

export OS_PROJECT_DOMAIN_ID=default
export OS_USER_DOMAIN_ID=default
export OS_PROJECT_NAME=admin
export OS_TENANT_NAME=admin
export OS_USERNAME=admin
export OS_PASSWORD=$(cat /etc/kolla/passwords.yml | grep "keystone_admin_password" | awk '{print $2}')
export OS_AUTH_URL=http://${ADDRESS}:35357/v3
export OS_IDENTITY_API_VERSION=3
EOF

bash ./import_image.sh

bash ./setup_network.sh

echo "Login using http://${ADDRESS} with default as domain,  admin as username, and $(cat /etc/kolla/passwords.yml | grep "keystone_admin_password" | awk '{print $2}') as password"
