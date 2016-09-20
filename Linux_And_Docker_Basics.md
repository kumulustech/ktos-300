# Basics of Linux and Docker for OpenStack (with Kolla)

Deploying OpenStack has become significantly simpler in recent years with a shift to using Linux Containers (specifically as defined and deployed via the Docker suite of tools) and the OpenStack Kolla project for "contaienrizing" and providing an initial deployment and operations framework.

In this lab we'll look at some of the operational interactions needed to work with Docker and specifically with gaining access to the services and undersatnding the enviornment around the Dockerization of the OpenStack middleware service components.

Specifically, we'll first cover some basic Linux tools, and then some specific Docker commands that will be of use as we explore the system enviornment.

## Linux specifics

There are plenty of tutorials and even multi-day classes for Linux neophytes, but we'll look to cover just some of the basics.

1) File system interaction:

To see what's in a directory:
```
ls
```
this will provide a listing of the files in the directory
  or
```
ls -la
```
Which provides more information including "hidden" directories and files that begin with a '.'

```
[vagrant@localhost ~]$ ls -la
total 32
drwx------. 4 vagrant vagrant 4096 Sep 19 05:21 .
drwxr-xr-x. 3 root    root    4096 Sep  6 09:27 ..
-rw-------. 1 vagrant vagrant  792 Sep 19 06:54 .bash_history
-rw-r--r--. 1 vagrant vagrant   18 Aug  2 16:00 .bash_logout
-rw-r--r--. 1 vagrant vagrant  193 Aug  2 16:00 .bash_profile
-rw-r--r--. 1 vagrant vagrant  231 Aug  2 16:00 .bashrc
drwx------. 3 vagrant vagrant 4096 Sep 19 05:21 .cache
drwx------. 2 vagrant vagrant 4096 Sep  6 09:28 .ssh
```

Note that the first part of the ls section provides information about the type of file (d for directory, - for normal file, etc.), followed by three sets of three permission 'bits', each set of three bits defines "Read" "Write" and "eXecute" permissions for "User" "Group" and "World".  Usually this is important for:

Security, change the permissions so only the user can read/write the file

```
chmod 0600 filename
```

Executabilty, set a script so that it can be directly executed from the command line

```
chmod 0755 filename.sh
```

Then there are the user and group names that the file belongs to, the size on disk in bytes, the date the file was last touched or modified, and the filename

```
cd /a/directory/path
```

Change directory to a path.

2) Executing a script/program

If the script isn't in the execution "PATH", then often it is necessary to preceed the script with a "./" as in:

```
./run_this_script.sh
```

Some script files really want to set environment variables (openrc.sh for example), and while they are often formatted to run as a script, the need to be "sourced" instead so that the enviornment they run in is the same as the one running the script.

```
source openrc.sh
```

or  a shortcut:

```
. openrc.sh
```

3) Environment variables

Often programs need parameters in order to run properly with variable input. it is possible to set these parameters in the "environment" in which a tool/script runs by setting environment variables, such as:

```
export OS_USERNAME=admin
```

If the tool is properly configured to read these sorts of environment variables, then the script will not need to have the parameter passed on the command line directly.

```
nova list --os-username=admin
export OS_USERNAME=admin
nova list
```

Both ```nova list``` commands will provide the same output.  the actual parameter or environment variable names will likley need to be discovered through interrogation of the documentation.

```
env | grep OS_USERNAME
```

This is a "two fer".  env prints the current environment, and grep is a regular expression search.  This is a useful pattern for filtering the output of a parameter.

4) File manipulation

```
cat >> file <<EOF
this text wil end up in file
and if file has text in it already
this text will be appended!
use a single > if you want
to overwrite the file
EOF
```

```
less file
```

will show the file contents one page at a time.  "q" will quite "f" will follow the end of the file (useful for log files like /var/logl/nova/scheduler.log)

```
rm file
```

remove a file

###Exercises

- create a file with cat that exports the "OS_DATE" environment variable
- look at what is in the file with less
- change the file permissions to include the execute bits
- "source" the file
- check the environment for the OS_DATE environment variable
- explore the directory environment with cd and ls {hint: cd / takes you to the root of the filesystem}

## Some Docker commands

```
docker ps
```

What is running in docker. Often we want to find the "name" or last parameter of the ps command for a specific container to a) ensure it's running, and b) find the name of the container in order to introspect it.

```
docker inspect container_name
```

The output of this command has very useful information, specifically, any volume mappings, where "external" directories are mapped to different directory paths in the container.  For example:

/etc/kolla/nova-compute/ is mapped to /etc/nova/ in the nova-compute container, and we can find this out via the ```inspect``` command.

```
docker exec -itu 0 container_name bash
```

This will give us a shell (bash) in the container namespace as the "root" user. This is often important for some debug stagets.  remove the 'u 0' parameter and argument in order to log in as the internal process owner user in the openstack kolla derived containers.

```
docker stop container_name
```

Halt (but do not remove) the container.  This is a way to ensure the container is not running, but keeps it's configuration.

```
docker run container_name
```

Start a container that's been previously stopped, or start a container by pulling the image either from the local "cache" of images ```docker images``` or from the defined upstream image registry (often docker hub unless a local resource has been configured)

```
docker restart container_name
```

Restart the container (stop/start). Often used when modifying configurations, either external, or within the container itself (edits via docker exec "presist" with the current container deployment)

### Exercises

- Find the docker image running the openstack nova-compute process
- Connect to the container as the UID 0 (root) user, and navigate to the /etc/nova/nova.conf file
- 
