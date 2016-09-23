#!/bin/bash
set -x
fallocate -l 6G /root/sdf
pv_name=$(losetup --find --show /root/sdf)
pvcreate $pv_name
vgcreate cinder-volumes $pv_name

