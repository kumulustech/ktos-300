# OpenStack Networking with Neutron

The networking functionality can really be broken down into a few key aspects:
1) L2 connectivity (with L3 networks associated for enabling that connectivity in most cases)
2) L3 router/NAT service functionality
3) L3 based security

There are a number of additional service functions that we will not necessarily have time to review in the lab:
- gbp, Group Based Policy as a service connectivity model
- lbaas, Load Balancing service, although an extra credit is to try to deploy this
- fwaas, vpnaas

## Create, Delete L2 segments

```
openstack network
```

- you should have a public/private network and router already from the setup scripts
- you should still have a VM running on the private network from the previous lab(s)

- create yet another network
 - spin up an instance on it, can you reach any of the other VMs from the new instance (via the console)
 - can you even attach a VM to it?

```
openstack subnet
```

- create a subnet (RFC-1918 address space) and associate it with the previously created network
- now spin up an instance.
  - select the newly created network
  - ca you reach other instances?
### Extra Credit
  - select a specific IP address (from the subnet range) for your instance on boot
  - modify the network, ad a DNS server (8.8.8.8)

```
openstack router
```
- use the currently defined router and create a mapping between the newly created subnet and the public internet.
- create a floating IP and associate it with the VM
- can you reach any of the instances not on the new network?
  - if not, any idea why?
- create another router, connect it to both the public and private networks
- move the new subnet to this router
  - you will have to release and remove your FloatingIP
- once the network is attached, are you able to communicate with the VM on the other network?

```
openstack security group
```

- Review the "default" group parameters
- Create a new security group, and allow inbound ICMP messages, and TCP on port 22
- Associate the security group with both of the running VMs
  - can you now ping between the entities

## Extra Credit
- what do you need to do to access the other systems?
  - explain it to the instructor
