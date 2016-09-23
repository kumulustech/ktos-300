# Orchestrating OpenStack - HEAT

While there are already small elements of automation embedded in all of the OpenStack services, there is always a need for another layer.  One such layer is the concept of a template that describes the relationships between elements, and this is the space that HEAT fills in the OpenStack service space.  There are other automation elements as well, such as Mistral which is a workflow based model for automation, but they have more to do with application level automation, while HEAT focuses on the system.

## The Setup

We will require a Centos Image, as the Cirros image is not the appropraite base for the "bastion" host we are buidling.  The goal is to have a VM running that can also run the OpenStack client tools against our OpenStack system.

To that end, a Centos 7 image needs to be loaded into glace.

### Exercise
- load a centos 7 image
- ensure you have a ssh key installed as well

## The template

Everything revolves around the template, so this is the one we'll be using to explore the basic features of HEAT:

```
heat_template_version: 2013-05-23

description: Simple template to deploy a bastion host with the CLI tools

parameters:
  key_name:
    type: string
    label: Key Name
    description: Name of key-pair to be used for compute instance
  image:
    type: string
    label: Image Name
    default: centos
    description: Image to be used for compute instance
  instance_type:
    type: string
    label: Instance Type
    default: m1.small
    description: Type of instance (flavor) to be used
  network:
    type: string
    label: Network Name
    default: private
    description: Newtork name to assocaite server with
  public_net:
    type: string
    label: Public Network
    default: public
    description: Newtork name for Floating IPs
  tenant_name:
    type: string
    label: Tenant Project Name
  user_name:
    type: string
    label: Tenant User Name
  floating_ip_id:
    type: string
    label: ID of Floating IP

resources:
  cloud_tools:
    type: OS::Nova::Server
    properties:
      key_name: { get_param: key_name }
      image: { get_param: image }
      flavor: { get_param: instance_type }
      networks:
        - port: { get_resource: server_1_port }
      name: { get_param: user_name }
      admin_user: cloud-user
      user_data:
        str_replace:
          template: |
            #!/bin/bash
            #
            # Setup a CentOS VM with the OpenStack Cloud Tools

            user=`ls /home | head -1`
            # Create a local password
            passwd $user <<EOF
            DiffiCultPassWordToRemember
            DiffiCultPassWordToRemember
            EOF

            chsh -s /bin/bash $user

            yum update -y

            yum install python-setuptools python-devel -y
            yum groupinstall "@Development tools" -y
            yum install libffi-devel openssl-devel -y

            easy_install pip

            clients='nova
            neutron
            glance
            heat
            cinder
            designate
            openstack
            keystone'

            for n in ${clients}
            do
             pip install python-${n}client
            done

            pip install python-swiftclient
            easy_install --upgrade requests[security]


            echo "`ip addr show eth0 | awk '/ inet / {print $2}' | cut -d\/ -f1`  `hostname`" >> /etc/hosts

            cat > /home/$user/openrc.sh <<EOF
            #!/bin/bash
            export OS_TENANT_NAME="$tenant_name"
            export OS_USERNAME="$user_name"
            export OS_PROJECT_DOMAIN_ID=default
            export OS_USER_DOMAIN_ID=default
            export OS_PROJECT_NAME=admin
            export OS_TENANT_NAME=admin
            export OS_AUTH_URL=http://localhost:35357/v3
            export OS_IDENTITY_API_VERSION=3

            echo "Please enter your OpenStack Password: "
            read -sr OS_PASSWORD_INPUT
            export OS_PASSWORD=\$OS_PASSWORD_INPUT

            export PS1='[\u@\h \W(admin)]\$ '
            EOF

          params:
            $tenant_name: { get_param: tenant_name}
            $user_name: { get_param: user_name }

  server_1_port:
    type: OS::Neutron::Port
    properties:
      network: { get_param: network }
  # server_1_floating_ip:
  #   type: OS::Neutron::FloatingIP
  #   properties:
  #     floating_network: { get_param: public_net }
  # server_1_floating_ip_association:
  #   type: OS::Neutron::FloatingIPAssociation
  #   properties:
  #     floatingip_id: { get_resource: server_1_floating_ip }
  #     port_id: { get_resource: server_1_port }

  server_1_floating_ip_association:
    type: OS::Neutron::FloatingIPAssociation
    properties:
      floatingip_id: { get_param: floating_ip_id }
      port_id: { get_resource: server_1_port }

outputs:
  server_floating_ip:
    description: The Floating IP address of the deployed server
    value: { get_attr: [floating_ip_id, floating_ip_address] }
  server_info:
    description: values of server
    value: { get_attr: [cloud_tools, show]}
```

The input to this script includes parameters like the ssh key that would have been uploaded in an earlier lab, and the username and project name.  While some of the parameters are defaults that should be adequate to launch the instance.

### Launch via Horizon
Find the Orchestration section of Horizon and:

- load the current template above
- provide the required parameters on the second page
- launch the instance

Assuming the instance launches appropriately, investigate the current state as described both by the Orchestration pages (including the graphical interaction diagram and the functional state of the separate orchestration elements)

- look at the instances tab of the Compute table, do the resources match
- the same question can be asked for network

### Launch via CLI

We have two options:

```
heat create
```

or

```
openstack stack create
```

- Use the create command to launch the stack, passing the required (and not defaulted) parameters on the command line.


### Extra Credit

- It is also possible to pass the parameters via a properties file.  Create such a file and launch the stack again.
- Update the template by adding a second compute instance (it doesn't need a floating IP etc.), load the updated template, and Update the stack
