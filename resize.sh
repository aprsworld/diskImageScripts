#!/bin/sh
# Automatic Image file resizer
#
# NOTE: This script will modify the original image!
# NOTE: This script is not tested with any partition types other than DOS/MBR
# and is also not tested with logical partitions.  DON'T USE THIS FOR THOSE!
#
# This script will resize the last ext4 partition in a disk image to the
# minimum size needed to hold it's files plus any extra space requested.
# It will then truncate the image file to the appropriate size.
#
# Written by "David A. Russell" <david@aprsworld.com>
strImgFile=$1

user=$(whoami)
if [ ! "root" = "$user" ]; then
	echo "ERROR:  This script needs to be run as root!"
	echo "Usage: sudo ./resize.sh <Image File> [<extraSpaceinMB>]"
	exit 127
fi

if [ -z $1 ]; then
	echo "ERROR: No Image File specified!"
	echo "Usage: sudo ./resize.sh <Image File> [<extraSpaceinMB>]"
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
	extraSpace="4"
else
	extraSpace="$2"
fi

if [ $extraSpace -lt 4 ]; then
	echo "ERROR:  You must specifiy at least 4 extra MegaBytes."
	exit 127
fi
extraSpace=$(( $extraSpace * 1048576 ))

# Get partition info
partinfo_last=$(parted -ms $1 unit B print | tail -n 1)
part_type=$(echo $partinfo_last | cut -d : -f 5)
part_num=$(echo $partinfo_last | cut -d : -f 1)
part_start=$(echo $partinfo_last | cut -d : -f 2 | sed s/B$//)
part_size=$(echo $partinfo_last | cut -d : -f 4 | sed s/B$//)
if [ ! "ext4" = "$part_type" ]; then
	echo "ERROR: Last partition is not an ext4 filesystem!"
	exit 1
fi

# Setup loopback
echo "Setting up loopback device..."
loopback=$(losetup -f --show -o $part_start $1)
if [ $? -ne 0 ]; then
	echo "ERROR: Failed to create loopback device!"
	exit 2
fi
trap 'losetup -d $loopback' EXIT INT TERM HUP

# Check filesystem
echo "Checking filesytem to be resized..."
e2fsck -f -p $loopback
if [ $? -ne 0 ]; then
	echo "ERROR: Filesystem is not clean or automatically repairable!"
	exit 3
fi

# Calculate minimum size
minsize=$(resize2fs -P $loopback | cut -d : -f 2)
blocksize=$(tune2fs -l $loopback | grep -i 'block size' | cut -d : -f 2) 
minsize=$(( $minsize * $blocksize ))
newsize=$(( $minsize + $extraSpace ))
if [ $newsize -gt $part_size ]; then
	echo "ERROR:  New partition size is larger than existing."
	exit 4
fi

# Resize filesystem
echo "Resizing filesystem..."
newsize=$(( $newsize / $blocksize ))
resize2fs -p $loopback ${newsize}
if [ $? -ne 0 ]; then
	echo "ERROR:  Could not resize filesystem!"
	exit 5
fi
sleep 1
newsize=$(( $newsize * $blocksize ))

echo "Updating Partition Table..."
part_end=$(( $part_start + $newsize ))
parted -m $1 unit B resizepart $part_num $part_end yes
if [ $? -ne 0 ]; then
	echo "ERROR:  Could not update partition table!"
	exit 6
fi

echo "Truncating image to final size..."
end_byte=$(parted -ms $1 unit B print | tail -n 1 | cut -d : -f 3 | sed s/B$//)
end_byte=$(( $end_byte + 1 ))
truncate -s $end_byte $1
if [ $? -ne 0 ]; then
	echo "ERROR:  Could not truncate image file!"
	exit 7
fi

echo "All done!"
exit 0
