#!/bin/sh
# Automatic Image file partition mounter
#
# Written by "David A. Russell" <david@aprsworld.com>
strImgFile=$1

user=$(whoami)
if [ ! "root" = "$user" ]; then
	echo "ERROR:  This script needs to be run as root!"
	echo "Usage: sudo ./mount.sh <Image File> <Partition> <Mount Point>"
	exit 127
fi

if [ -z $1 ]; then
	echo "ERROR: No Image File specified!"
	echo "Usage: sudo ./mount.sh <Image File> <Partition> <Mount Point>"
	exit 127
fi

if [ ! -e $1 ]; then
	echo "ERROR:  Image file does not exist!"
	exit 127
fi

partinfo=$(parted -ms $1 unit B print 2> /dev/null)
if [ $? -ne 0 ]; then
	echo "ERROR:  Image file is not a valid disk image!"
	exit 127
fi

if [ -z $2 ]; then
	echo "ERROR:  No Partition specified!"
	echo "Usage: sudo ./mount.sh <Image File> <Partition> <Mount Point>"
	exit 127
fi

if [ -z $3 ]; then
	echo "ERROR:  No Mount Point specified!"
	echo "Usage: sudo ./mount.sh <Image File> <Partition> <Mount Point>"
	exit 127
fi

# Get partition info
partinfo=$(parted -ms $1 unit B print | grep "^$2:")
part_type=$(echo $partinfo | cut -d : -f 5)
part_num=$(echo $partinfo | cut -d : -f 1)
part_start=$(echo $partinfo | cut -d : -f 2 | sed s/B$//)
part_size=$(echo $partinfo | cut -d : -f 4 | sed s/B$//)
if [ -z $partinfo ]; then
	echo "ERROR:  Could not find partition info!"
	exit 1
fi

# Setup loopback
echo "Setting up loopback device..."
loopback=$(losetup -f --show -o $part_start $1)
if [ $? -ne 0 ]; then
	echo "ERROR: Failed to create loopback device!"
	exit 2
fi

echo "Mounting filesystem..."
mount $loopback "$3"
if [ $? -ne 0 ]; then
	losetup -d $loopback
	echo "ERROR:  Could not mount filesystem!"
	exit 4
fi

echo 'All done, umount filesystem and type `sudo losetup -d' $loopback'` when done!!!'
exit 0
