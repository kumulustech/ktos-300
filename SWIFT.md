# Storing Objects Since 2010 - Swift
## And not that programming language from Apple either

Object storage is a file system service that, at least in the mode of use in cloud, is focused on Web based interactions. This is different than the sorts of interactions one has with most file systems that are operating system mediated.

So let's explore Swift.  Firstly, we want to be able to add and delete items.  Be careful of one thing, if you define a path to yoru file, that path will be included (by the default swift client) as a part of the "object URI".  I.e, if I ask to store /root/test/file.txt, the object will be something like:

```
http://endpoint:port/account/container/root/test/file.txt
```

as opposed to the perhaps anticipated

```
http://endpoint:port/account/container/file.txt
```

So lets start!
0) A little housekeeping:  The default Kolla installation does not include swift as a running service by default.  uncomment the swift parameter in the startup script, and rerun the "deploy" process:

```
for n in `docker ps -qa`; do docker stop $n; docker rm -v $n; done
setup_swift.sh
kolla-ansible deploy
```

1) we need a test file. If you don't have one, you can always grab a picture of one of my cats:
- https://kumul.us/wp-content/uploads/2016/09/22113429996_6fc64498eb_o.jpg

2) we need a client:

```
pip install python-swiftclient

swift post
swift upload
```
or use the openstack cli

```
openstack container
openstack object
```

Hint, you have to create the container first, then you can upload the object.

One of the interesting interactions with objects is that you can often directly download them, for which you need the direct link, or the "object URL"

An object URL should look something like this:

```
http://147.75.100.59:8080/v1/AUTH_cc51f6b63809444182cba94f31c62d1d/chetah/chetah.jpg
```

### Exercises
- upload an object into a container (the container name is text, the object is the file name of the object you want to upload)
- download the object via one of the CLI tools
- does the same set of operations work on the UI?
- find the full object URI, and paste it into the browser on your laptop, do you get the file back that way as well?


## Access Control

There are two aspects of SWIFT access control:
- User access/credentials
- Time to Live and/or Time to Access

For Time to Access, the principal mechanism is the Temporary URL or TempURL.

- set up the TempURL secret key for your account with the ```swift``` or ```openstack``` clients
- create a TempURL to read your object for 120s, try to read the file until it times out


A feature of Swift that can also be very useful is to upload an image with an expiration date, or a Time-To-Live. This is accomplished on the CLI with the same swift upload command as before, with the addition of passing an additional header. Use the X-Delete-After header.

You can also use the X-Delete-At header, which takes the Unix Epoch time for deletion. In bash, you should be able to get the epoch version of a date with the following (for example 16:15-27-Feb-15):


date -j -f "%H:%M-%d-%B-%y" 16:15-27-FEB-15 +%s
1425078910

- Upload an object to be deleted afer 300 seconds
- Upload an object to be deleted at 12:30pm on the 22n of Jan, 2016

If you check either after the TTL expires, or after the date/time specified as an Epoch, you should no longer see your object!

What if we combine both expiration and a private token enabled container, and script up a little test?

## Extra credit
Create a script to:
 - set the secret key
 - load a file with a 120s TTL
 - check to see if the file exists on a 15s interval
 - report after 120s wether the file is still in existence or not

## Container access define

Container access has read or write permissions setable, explore access limits

swift upload new-container test_file.txt
swift post new-container -r '.r:*,.rlistings'

- find the public container URL
