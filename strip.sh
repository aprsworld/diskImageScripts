#!/bin/sh
# Image file truncator
#
# NOTE:  THIS SCRIPT WILL MODIFY THE ORIGINAL FILE PASSED IN!
# NOTE:  DO NOT USE THIS ON IMAGES WITH LOGICAL PARTITIONS OR USING A PARTITION
# TYPE OTHER THAN DOS/MBR!!!
#
# This script will take a disk image file and remove extra partitions
# and make the image exactly the size of remaining partitions stripping
# away possible excess caused by a dd'd disk file. 
#
# So if you have an image file you dd'd off a flash card and run this
# script it will truncate it to the size of the image including all
# partitions up the one specified.
#
# Example: You have an image you dd'd from a disk and want to make the file
# only as large as needed - `./strip.sh <imagefile>`
#
# Example: You have an image with 2 or more partitions and you only
# want to keep the first two - `./strip.sh <imagefile> 2`
#
# Written by "David A. Russell" <david@aprsworld.com>
strImgFile=$1
lastpartnum=$2

if [ -z $1 ]; then
	echo "Usage: ./strip.sh <Image File> [<Last Partition #>]"
	echo "Read comments in script for more info."
	exit 127
fi

if [ ! -e $1 ]; then
	echo "Error : Not an image file, or file doesn't exist"
	exit 127
fi

echo "This will truncate '$1'.  Press Enter to continue."
read discard

origsize=$(stat -c "%s" $1)

if [ ! -z $2 ]; then
	echo "Removing all partitions after ${2}..."
	/sbin/parted -ms $1 rm $(( $2 + 1 ))-10
	if [ $? -ne 0 ]; then
		echo "Error: Could not update partition table; Aborting."
		exit 1
	fi
fi

endresult=$(/sbin/parted -ms $1 unit B print | tail -n 1 | cut -d : -f 3 | sed s/B$// );
endresult=$(( $endresult + 1 ))
echo "Truncating file to $endresult bytes..."
truncate -s $endresult $1
if [ $? -ne 0 ]; then
	echo "ERROR: Could not truncate file!"
	exit 2
fi

echo "------------------------------------"
echo "Original Image Size: $origsize bytes"
echo "New Image Size: $endresult bytes"
