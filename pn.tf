# Create a Virtual Machine


# If you don't already have a domain defined in Digital Ocean

#resource "digitalocean_domain" "opsits-com" {
#    name = "opsits.com"
#}

# create a master device resoruce in packet.net
resource "packet_device" "kolla" {
        hostname = "kolla"
        plan = "baremetal_0"
        facility = "ewr1"
	operating_system = "centos_7_image"
        billing_cycle = "hourly"
        project_id = "320c2c2f-6876-4621-929a-93a47e07d2da"
}
resource "packet_device" "kolla-cmp" {
        hostname = "kolla-cmp"
        plan = "baremetal_0"
        facility = "ewr1"
	operating_system = "centos_7_image"
        billing_cycle = "hourly"
        project_id = "320c2c2f-6876-4621-929a-93a47e07d2da"
}
resource "packet_device" "student1" {
        hostname = "student1"
        plan = "baremetal_0"
        facility = "ewr1"
	operating_system = "centos_7_image"
        billing_cycle = "hourly"
        project_id = "320c2c2f-6876-4621-929a-93a47e07d2da"
}
resource "packet_device" "student2" {
        hostname = "student2"
        plan = "baremetal_0"
        facility = "ewr1"
	operating_system = "centos_7_image"
        billing_cycle = "hourly"
        project_id = "320c2c2f-6876-4621-929a-93a47e07d2da"
}
resource "packet_device" "student3" {
        hostname = "student3"
        plan = "baremetal_0"
        facility = "ewr1"
	operating_system = "centos_7_image"
        billing_cycle = "hourly"
        project_id = "320c2c2f-6876-4621-929a-93a47e07d2da"
}
resource "packet_device" "student4" {
        hostname = "student4"
        plan = "baremetal_0"
        facility = "ams1"
	operating_system = "centos_7_image"
        billing_cycle = "hourly"
        project_id = "320c2c2f-6876-4621-929a-93a47e07d2da"
}
######resource "packet_device" "student5" {
######        hostname = "student5"
######        plan = "baremetal_0"
######        facility = "ams1"
######	operating_system = "centos_7_image"
######        billing_cycle = "hourly"
######        project_id = "320c2c2f-6876-4621-929a-93a47e07d2da"
######}

# create a master device resoruce in packet.net
#resource "packet_device" "minion" {
#        hostname = "minion"
#        plan = "baremetal_1"
#        facility = "ewr1"
#	operating_system = "ubuntu_16_04"
#        billing_cycle = "hourly"
#        project_id = "320c2c2f-6876-4621-929a-93a47e07d2da"
#}


# Add a pointer to the new IP address
# Note that the default TTYL is 1800 seconds, so it will take
# up to 30 minutes in this enviornment for the record to time out.

resource "digitalocean_record" "kolla" {
    domain = "opsits.com"
    type = "A"
    name = "kolla"
    value = "${packet_device.kolla.network.0.address}"
}
resource "digitalocean_record" "kolla-cmp" {
    domain = "opsits.com"
    type = "A"
    name = "kolla-cmp"
    value = "${packet_device.kolla-cmp.network.0.address}"
}
resource "digitalocean_record" "student1" {
    domain = "opsits.com"
    type = "A"
    name = "student1"
    value = "${packet_device.student1.network.0.address}"
}
resource "digitalocean_record" "student2" {
    domain = "opsits.com"
    type = "A"
    name = "student2"
    value = "${packet_device.student2.network.0.address}"
}
resource "digitalocean_record" "student3" {
    domain = "opsits.com"
    type = "A"
    name = "student3"
    value = "${packet_device.student3.network.0.address}"
}
resource "digitalocean_record" "student4" {
    domain = "opsits.com"
    type = "A"
    name = "student4"
    value = "${packet_device.student4.network.0.address}"
}
######resource "digitalocean_record" "student5" {
######    domain = "opsits.com"
######    type = "A"
######    name = "student5"
######    value = "${packet_device.student5.network.0.address}"
######}

#resource "digitalocean_record" "minion" {
#    domain = "opsits.com"
#    type = "A"
#    name = "minion"
#    value = "${packet_device.minion.network.0.address}"
#}


