# Using and managing Keystone

Keystone has two main functions:
- Provide a catalog of service endpoints (how to get ahold of other services)
- Provide an authentication and authorization service for the other OpenStack components

## Catalog service

Before we can do much of anything we need to have the command line tools installed in a location where they can be used to access the OpenStack environment.  If they weren't installed as  a part of the initial deployment, we can do so with the following command:

```
pip install python-openstackclient
```

We also need to have a set of credentials set up in order to help map to the openstack environment:

```
cat > ~/openrc.sh << EOF
#!/bin/bash

# set environment variables for Starmer's OpenStack demo install

# "source this file, don't subshell" predicate inspired by
# http://stackoverflow.com/a/23009039/282912

if [ "$0" = "$BASH_SOURCE" ] ; then
    echo "You ran this script instead of sourcing it."
    echo "  usage: source $0"
    echo "Aborting."
    exit 1
else
    echo "Setting environment variables in the current shell"
fi

set -o xtrace
export OS_PROJECT_DOMAIN_ID=default
export OS_USER_DOMAIN_ID=default
export OS_PROJECT_NAME=admin
export OS_TENANT_NAME=admin
export OS_USERNAME=admin
export OS_PASSWORD=$(cat /etc/kolla/passwords.yml | grep "keystone_admin_password" | awk '{print $2}')
export OS_AUTH_URL=http://$(hostname):35357/v3
export OS_IDENTITY_API_VERSION=3
set +o xtrace
EOF

```

Copy and paste the above into the command line on your "ALL-IN-ONE" instance, and then source the resulting "openrc.sh" script:

```
source openrc.sh
```

the catalog service is of most use to the other parts of openstack, but we can manipulate it with the openstack client if need be. In our case, we'll just print it:

```
openstack endpoint list
```

### Extra Credit
- explore the help around endpoint list: ```openstack help endpoint list```
   - can you change the way the output is presented? perhaps in a way that is more programatically filterable?


## Users, Domains, Projects, Roles

```
openstack roles
```

- Discover the available Roles
- create a new role 'serious'
  - how do you make this role "meaningful"
- associate the new role with the admin user and admin project

```
openstack domain
```

- Discover the available domains
- create a new domain 'better'
- look through the help for the domain command, what else can you define?

```
openstack project
```

- What projects exist?
- Create a new project 'faster'
- Add the faster project to the 'better' domain
- How else can you modify the project (look to the help, young jedi)

```
openstack user
```

- List the Users
- Create the 'stronger' user
- add the user to the 'faster' project with the 'serious' role

### Extra Credit

- Can you create a user in a particular domain, and associated with a particular project?
 - user 'more' should also be in domain 'better' and project 'also' and can also have the 'serious'
- Can you do the above operations in Horizon?
