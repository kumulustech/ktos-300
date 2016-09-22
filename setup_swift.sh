#!/bin/bash
set -x
# set up three volumes (loopbacks in this demo)
index=0
for d in sdc sdd sde; do
    free_device=$(losetup -f)
    fallocate -l 1G /tmp/$d
    losetup $free_device /tmp/$d
    parted $free_device -s -- mklabel gpt mkpart KOLLA_SWIFT_DATA 1 -1
    sudo mkfs.xfs -f -L d${index} ${free_device}p1
    (( index++ ))
done

export NETWORK_INTERFACE=`grep '^network_interface: .*' /etc/kolla/globals.yml | awk -F'[ \t\n]+' '{print $2}' | tr -d '\"'`

export KOLLA_INTERNAL_ADDRESS="$(ip -4 addr show ${NETWORK_INTERFACE} | grep "inet" | head -1 |awk '{print $2}' | cut -d/ -f1)"

export KOLLA_BASE_DISTRO=centos
export KOLLA_INSTALL_TYPE=binary
export TAG=2.0.2

# Object ring
docker run \
  -v /etc/kolla/config/swift/:/etc/kolla/config/swift/ \
  kolla/${KOLLA_BASE_DISTRO}-${KOLLA_INSTALL_TYPE}-swift-base:${TAG} \
  swift-ring-builder /etc/kolla/config/swift/object.builder create 10 3 1

for i in {0..2}; do
  docker run \
    -v /etc/kolla/config/swift/:/etc/kolla/config/swift/ \
    kolla/${KOLLA_BASE_DISTRO}-${KOLLA_INSTALL_TYPE}-swift-base:${TAG} swift-ring-builder \
    /etc/kolla/config/swift/object.builder add r1z1-${KOLLA_INTERNAL_ADDRESS}:6000/d${i} 1;
done

# Account ring
docker run \
  -v /etc/kolla/config/swift/:/etc/kolla/config/swift/ \
  kolla/${KOLLA_BASE_DISTRO}-${KOLLA_INSTALL_TYPE}-swift-base:${TAG} \
  swift-ring-builder /etc/kolla/config/swift/account.builder create 10 3 1

for i in {0..2}; do
  docker run \
    -v /etc/kolla/config/swift/:/etc/kolla/config/swift/ \
    kolla/${KOLLA_BASE_DISTRO}-${KOLLA_INSTALL_TYPE}-swift-base:${TAG} swift-ring-builder \
    /etc/kolla/config/swift/account.builder add r1z1-${KOLLA_INTERNAL_ADDRESS}:6001/d${i} 1;
done

# Container ring
docker run \
  -v /etc/kolla/config/swift/:/etc/kolla/config/swift/ \
  kolla/${KOLLA_BASE_DISTRO}-${KOLLA_INSTALL_TYPE}-swift-base:${TAG} \
  swift-ring-builder /etc/kolla/config/swift/container.builder create 10 3 1

for i in {0..2}; do
  docker run \
    -v /etc/kolla/config/swift/:/etc/kolla/config/swift/ \
    kolla/${KOLLA_BASE_DISTRO}-${KOLLA_INSTALL_TYPE}-swift-base:${TAG} swift-ring-builder \
    /etc/kolla/config/swift/container.builder add r1z1-${KOLLA_INTERNAL_ADDRESS}:6002/d${i} 1;
done

for ring in object account container; do
  docker run \
    -v /etc/kolla/config/swift/:/etc/kolla/config/swift/ \
    kolla/${KOLLA_BASE_DISTRO}-${KOLLA_INSTALL_TYPE}-swift-base:${TAG} swift-ring-builder \
    /etc/kolla/config/swift/${ring}.builder rebalance;
done
