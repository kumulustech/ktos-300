# Deploying OpenStack With Kolla and Docker

We'll deploy a Virtual Machine in order to run the Kola environment locally, though an external/remote VM is also an appropriate choice.

There are three possible pathways for implementing this solution:

1) Vagrant for Mac, Linux, or Windows based machines (laptop or other)
2) Manual for a local virtualization manager with a baseline Virtual Machine
3) Manual on a remote system (bare metal or nested capable virtual machine)

## Deploying with Vagrant
Prerequisites:
 - At least 6GB of systems memory
 - At leaset 10GB of free disk space

1) Download and install Vagrant
  https://www.vagrantup.com
2) Download and install VirtualBox
  https://www.virtualbox.org/wiki/Downloads
  You'll also want to install the guest additions for completeness
3) Download the Vagrant script created by Andrew Widdersheim from the repository where you found this document

4) Create a directory for the Vagrant file and it's data (which ends up in the .vagrant directory).  VirtualBox will store the system image in it's default location, which is usually in the local system users' home directory, so that file system needs to have ~10GB of disk space available.

5) run:

  vagrant up

6) Wait.  Depending on the upstream bandwidth available (and the speed of the Docker hub registry) the install can happen in as little as a few minutes, or as much as many hours.

At this point, the Vagrant run should spit out credentials for logging into the system, point a local web browser at the address provided, and use the login credentials defined. You will also need to specify the default domain for login purposes called "default"

7)  Now that you have a baseline OpenStack system, you are not quite ready to start virtual machines.  You still need to:

 - install a virtual machine image
 - create at least a local newtork
 - upload an ssh key and/or (depending on the image) force a password to be set on the image at boot time

We'll get to these in a moment.  But first:

## If you can't run Vagrant, or want to have a hand in configuring the enviornment:

1) We will need either an ISO image, or a virtual machine image for a virtualization platform.  A CentOS ISO is available for download from:

  http://isoredirect.centos.org/centos/7/isos/x86_64/CentOS-7-x86_64-Minimal-1511.iso

Alternatively, there is a CentOS VirtualBox (OVA packaged) image available here:

  https://drive.google.com/open?id=0B87WHaaJVqLrTkhacE5TMUdLZGs

2) Launch a Virtual Machine with the following configuration:
 - 2 cores
 - 4GB memory
 - 30GB disk space
 - at least 2 network interfaces
   (note, in virtualbox it is common to have a third "NAT Only" interface)
   the interfaces should be configured with DHCP addresses to allow remote access at least from the local system.
   if the "last" interface is configured as a bridge interface, then depending on the network to which the laptop is attached, it may be possible to leverage some of the other OpenStack network functions like "Elastic IPs" or Floating IPs in OpenStack parlance.
   (note: if you use the OVA image, you will need 3 networks: NAT, hostonly, and bridged)

3) Once the virtual machine has been launched and basic configuration has been applied, we will manually install the kolla tools as follows:

a) Log in to the virtual machine
b) copy/paste the following into the machine, or grab the script from the repository.

```setenforce 0
sed -i "s/^\s*SELINUX=.*/SELINUX=disabled/g" /etc/selinux/config

yum -y install epel-release

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

NETWORK_INTERFACE="eth0"
NEUTRON_INTERFACE="eth1"
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
sed -i "s/^keystone_admin_password:.*/keystone_admin_password: \
Koll@0penst@ck" /etc/kolla/passwords.yml
kolla-ansible prechecks
kolla-ansible pull
kolla-ansible deploy

echo "Login using http://${NETWORK_INTERFACE}/ with admin as username and $(cat /etc/kolla/passwords.yml | grep "keystone_admin_password" | awk '{print $2}') as password"
```
Note: It may be necessary to change the NETWORK_INTERFACE and NEUTRON_INTERFACE to map to the interface names of the system as built.  To determine the network interfaces, run:

  ip a

on the target system, and look for the 10.0.2.15 interface, that will be the NAT interface (for VirtualBox), the other two interfaces are then the ones that should be mapped to the Network and Neutron interfaces respectively (the bridged==neutron, the hostonly==network)

At the end of this process, it should be possible to log into the system following the instructions echoed at the end of the process.

## Alternate Alternate path

An ansible path is also available. Assuming you are able to run Ansible on your local machine, or install ansible on the remote machine and configure the inventory to point back at the local instance (ensure ssh is set up to allow root passwordless login)


## Configuring the "rest" of the system

We'll need the following resources:
 - an "openrc.sh" script,  which we can either manully create, or download via the Horizon user interface [Project->Access&Security=>API Access]
 or create one from the following template:

```
#!/bin/bash
echo "running this file is not adequate, you must 'source' it"
echo "source $0   or . $0"
export OS_PROJECT_DOMAIN_ID=default
export OS_USER_DOMAIN_ID=default
export OS_PROJECT_NAME=admin
export OS_TENANT_NAME=admin
export OS_USERNAME=admin
export OS_PASSWORD={admin_password_from_the_kolla_script}
export OS_AUTH_URL=http://${eth1_interface_ip}:35357/v3
export OS_IDENTITY_API_VERSION=3
```

save this file as "openrc.sh" and 'source' it:

```
. openrc.sh
```

 - to work with the CLI interface, we need the tools installed. This can be done on your local machine (and often this is very useful), or on the machine where OpenStack is installed (though this adds potential complications for ssh/public/private key management)

 ```
 http://docs.openstack.org/user-guide/common/cli-install-openstack-command-line-clients.html
 ```

 Or you can use this script:

```
#!/bin/bash
source ~/openrc.sh
yum install python-devel python-pip
pip install python-openstackclient python-keystoneclient python-glanceclient python-novaclient python-cinderclient python-neutronclient

```

 - a "cloud" image, either centos, or cirros {a lightweight "test" image}

```
   http://docs.openstack.org/image-guide/obtain-images.html
```

And again, we can install via Horizon [Project->Images=>Create Image], or via CLI:

```
curl http://cloud.centos.org/centos/7/images/CentOS-7-x86_64-GenericCloud.qcow2
openstack image create --container-formant bare --disk-format qcow2 --min-disk 1 \ --min-ram 512--public --file CentOS-7-x86_64-GenericCloud.qcow2 centos7
rm CentOS-7-x86_64-GenericCloud.qcow2
```

 - a network configuration.  This script can accelerate the configuration of our networks:

```
https://raw.githubusercontent.com/rstarmer/openstack-kolla-ansible/master/setup_net.sh
```

 This script will still need to have at least the 10.1.10 network addresses updated to map to the network on your bridged interface.
 This can also be accomplised via Horizon, but there is no "Wizard" to walk through the steps.

 - an ssh public/private key pair.  It's possible to create your own or have OpenStack create one for you (again via the Horizon interface) [Project->Access&Security=>Key Pairs]
 The benefit of creating your own, especially if you are on a Windows machine, is that you can usually use the tools built into the SSH terminal client to create keys, which will generate the right private format for the local system (putty is a notorious ssh client for keeping keys in a different format from the Unix "norm"). On a Linux (or Mac) system, open a terminal session and create a ssh pair, public and private as follows:

```
ssh-keygen -t rsa -N '' -f ~/.ssh/id_rsa
```
NOTE: If you install the CLI tools on the OpenStack AIO VM, you may want to create a local keypair to use as the source of your access to the OpenStack VMs

 this will create an id_rsa file (the private key, you don't normally share this), and the id_rsa.pub key (the public key, paste this on the back of your car, write it across the sky, load it into your OpenStack environment, into git, bitbucket, everywhere that you can think of etc.)

We need to get this key installed into OpenStack to make it useful, which can be done via horizon (the same Key Pairs page listed above).  Install the _PUBLIC_ key into OpenStack.

VIA CLI:

```
nova keypair-add --pub-key ~/.ssh/id_rsa.pub root
```

 - Finally, we should be able to boot a VM!

```
nova boot --flavor 2 --image xenial --nic net-id=`neutron net-list | awk '/private/ {print $2}'` --key-name=root centos7
```
