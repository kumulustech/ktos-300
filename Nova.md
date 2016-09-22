# VM Management in the Cloud - Nova
## And some storage and network interactions

The principal function of the Nova environment is to deploy virtual machines (and via similar models Ironic does so for Bare Metal, and Zun intendes to provide a model for individual container services).  Let's investigate the basics and a few variants of the initial deployment.

## Building a VM

```
openstack server
```

In order to deploy an instance, there are some common operations one might do such as determine what the current state of the server environment is, so:
- List the currently running instances
- Create a new VM
  - What information is needed?   image name, flavor {scale of instance}, ssh key name, network to connect to (there's currently normally only one, so this isn't required by default)
  - default "with image" create an ephemeral disk
  - create an image on volume

#### Note that Horizon will show different functions for different types of storage

```
openstack server group
```
While we have only a single instance, we can still see how the scheduler treats requests for affinity in scheduling.  Create two server groups, one with affinity type, one as anti-affinity.  Deploy two VMs in the affinity group, delete them, and then deploy two more in the anti-affinity group.  What are the results?


## VM storage manipulation

```
openstack server
```

- boot instance (ephemeral), log in and create a file on the file System
 e.g: cat > original.txt <<EOF
 this is a file
 and it is here
 EOF

- snapshot instance
- restart instance (if necessary)
- log in and remove file created
- restore from snapshot

- export snapshot (glance function)
- import snapshot as new image
- boot instance from new image

## VM size manipulation

```
openstack server resize
```

- select the next larger flavor, resize the image to this (tiny->small)
- can you resize the other way?
  why, or why-not

## VM Network service
While we'll look at Neutron next, there are still some common operations even if we just use the "generic" network model.  Specifically, FloatingIP allocation and association that is more commonly handled via nova.

```
openstack server ip floating
```

- assoicate a floating IP with the instnace
- from the VM (ssh or console into your OpenStack instance) log in to the deployed VM via the floating IP

In order to look at one of the other common operations, create another private network and turn on a VM via the command line
- what's different about this compared to the previous deployment
- review the help for  ```openstack server boot``` to look at the network interface operations

### Extra Credit

- Find and review the log files, paying special attention to the nova _scheduler_ function
- If the scheduler isn't "saying" much, enable debugging (from the container review)

### Extra Extra Credit
- rebuild your enviornment to enable cinder:
  - on the openstack system VM:  ```echo 'enable_cinder: "yes"' > /etc/kolla/globals.yml``` and then delete and re-build the openstck enviornment:

```
echo 'enable_cinder: "yes"' >> /etc/kolla/globals.yml
echo 'enable_swift: "yes"' >> /etc/kolla/globals.yml
echo 'enable_manila: "yes"' >> /etc/kolla/globals.yml

for n in `docker ps -qa`; do docker stop $n ; docker rm $n; done kolla-ansible deploy
```
- now create a volume from an image and boot from that volume
- boot an instance and ask the system to create a volume for the system's root
- "backup" the instance
- restore the "backup"
