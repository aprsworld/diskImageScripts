# Disk Image Scripts

This is a collection of scripts for working with disk image files.  They all
assume DOS/MBR partition style and that there are no Logical/Extended partitions.  BAD THINGS WILL HAPPEN OTHERWISE!

They should be fairly robust but they all work directly on the images themselves so destructive changes to the disk image are possible.


## strip.sh

'strip.sh' will strip remaining bytes off an image file.  If you specify a last
partition it will also strip off any partitions after that one.  This
script is useful for if you dd an image and want it to be the correct size
after dd'ing it.

### Examples:

* `./strip.sh imagefile` will truncate the file to exactly the size of the
	disk image.
* `./strip.sh imagefile 2` will remove any partitions after the 2nd one and will
	then truncate the file to exactly the size of the remaining image.



## resize.sh

'resize.sh' will resize the last partition provided it's an ext4 filesystem
to the minimum size needed to hold all files currently in it.  If specified
it will also keep an addition n MegaBytes of free space as well.  It then
truncates the image file to the correct size.  This file needs to be run as
root for access to the loopback devices.

### Examples:

* `sudo ./resize.sh imagefile` will resize the last partition to the minimum
	size it can be.
* `sudo ./resize.sh imagefile 500` will resize the last partition to the
	minimum size plus an addition 500 MegaBytes of space.



## mount.sh

'mount.sh' will automagically mount a partition in a disk image file.  Just
specify the imagefile, the partition number, and then where to mount.  It obviously needs to be run as root.

### Examples:

* `sudo ./mount.sh imagefile 2 /mnt` will mount the 2nd partition in imagefile
	to '/mnt'.  It will instruct you which loopback device was used for
	releasing it after umounting.  Usually /dev/loop0.  Make note of it!
