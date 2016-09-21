# Using Glance to manage images

Glance provides image management, and can both store images, or just store image pointers.

Let's explore both modes:

```
openstack image
```

- How can I create an image that is pulled from a remote http source?
- How about referencing another image as the source (a way to administratively share non-public images)
- Get a cirros image (http://download.cirros-cloud.net/0.3.4/cirros-0.3.4-x86_64-disk.img) onto the local disk, and upload the image

### Extra credit
  - How do I find where the image repository is (inspect...)

```
openstack image save
```

- Can I get an image back (more important when we talk about snapshots)

```
openstack image set
```

- how do I go about uploading the three parts of an Amazon AMI
  - why might I want to do this?
  - can I set the relationship between these componets?
- what else can I set/update about the image

## The Older API

Let's use the older api:

```
glance help
```

what's different about the commands available via the glance command?
- pay attention to the note at the end of the help output... Try that command
- Tell glance to point to an image on disk (without importing it)
  - verify this by looking for a image id in the on disk image repository

- Use the V1 API to create apointer to a local file
  - what happens to the on disk repository? (remember where that is?)

### Extra Credit
- launch a vm with the image you deployed
- log in and "touch" a file on the disk
- create a snapshot of your running image (nova command line or Horizon)
- save the image to disk (how big is it compared to when you first uploaded it?)
- delete the image in the glance repository
- reimport the image into glance
- boot the image, is it the same as you expected?
