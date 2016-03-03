#!/bin/bash
# Image file truncator
#
# NOTE:  DO NOT USE THIS ON IMAGES WITH LOGICAL PARTITIONS OR USING A PARTITION
# TYPE OTHER THAN DOS/MBR!!!
#
# This script will take a disk image file and remove extra partitions
# and make the image exactly the size of remaining partitions stripping
# away possible excess caused by a dd'd disk file. 
#
# So if you have an image file you dd'd off a flash card and run this
# script it will truncate it to the size of the image including all
# partitions up the one specified.  It's really not tested against
# logical partitions and assumes a DOS partition scheme.
#
# This script can also be used to simply remove trailing data from
# a dd'd disk image that is bigger than all the partitions.  Just
# specify the last partition and it will truncate to the right size.
#
# Example: You have an image with 2 or more partitions and you only
# want to keep the first two - ./strip.sh <imagefile> 2
#
# It works on the original image so is destructive!
#
# Written by "David A. Russell" <david@aprsworld.com>
strImgFile=$1
lastpartnum=$2

if [[ -z $1 ]]; then
echo "Usage: ./strip.sh <Image File> [<Last Partition #>]"
echo "Read comments in script for more info."
exit
fi

if [[ ! -e $1 ]]; then
echo "Error : Not an image file, or file doesn't exist"
exit
fi

echo "This will truncate '$1'.  Press Enter to continue."
read -s

origsize=`stat -c "%s" $1`

if [ ! -z $2 ]; then
	echo "Removing all partitions after ${2}..."
	part1=`/sbin/parted $1 -ms rm $(( $2 + 1))-10`
	if [ $? -ne 0 ]; then
		echo "Error: Could not update partition table; Aborting."
		exit 1;
	fi
fi

echo "Truncating file to minimal size to contain all remaining partitions..."
endresult=`/sbin/parted -ms $1 unit B print free | tail -1 | awk -F: ' { print substr($2,0,length($2)-1) } '`
truncate -s $endresult $1

echo "Original Image Size: $origsize"
echo "New Image Size: $endresult"
