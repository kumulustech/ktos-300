#!/bin/bash

n=$1
cat >> pn.tf <<EOF
resource "packet_device" "student${n}" {
        hostname = "student${n}"
        plan = "baremetal_0"
        facility = "ams1"
        operating_system = "centos_7_image"
        billing_cycle = "hourly"
        project_id = "320c2c2f-6876-4621-929a-93a47e07d2da"
}
resource "digitalocean_record" "student${n}" {
    domain = "opsits.com"
    type = "A"
    name = "student${n}"
    value = "\${packet_device.student${n}.network.0.address}"
}
EOF
