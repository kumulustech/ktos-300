# OpenStack Block Storage - cinder

For Cinder, we will have to enable additional servcies and re-build our openstack enviornment.

1) Delete any running VMs (they need to go away to allow us to re-create the containers)
2) We will also loose our image and networks, so the network and image scripts can re-create them quickly.

```
echo 'enable_cinder: "yes"' > /etc/kolla/globals.yml
echo 'enable_swift: "yes"' > /etc/kolla/globals.yml
echo 'enable_manila: "yes"' > /etc/kolla/globals.yml

for n in `docker ps -qa`; do docker stop $n ; docker rm $n; daemon-reload
kolla-ansible deploy
```

Once that's done, we can start creating Volumes, though it's possible you did this via the earlier Nova extra Credit.

- create a volume and associate it with a running VM
- log in to the VM, and create a file system on it:

```
mkfs.ext4 /dev/vdb
mount /dev/vdb /mnt
touch /mnt/file_to_prove_that_our_disk_is_the_same_one_we_initially_created
```

 - create a backup of this volume, and once complete
  - remove the file
  - detach the volume restore from backup
 - validate that the file is back

## Extra Credit
- create a second project
- transfer the volume from your project to the other project and assiciate it with a vm in that project (create a network, VM, etc.)
