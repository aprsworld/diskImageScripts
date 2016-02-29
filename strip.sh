#!/bin/bash
# Image file truncator
# Written by "David A. Russell" <david@aprsworld.com>
strImgFile=$1
lastpartnum=$2

if [[ -z $1 || -z $2 ]]; then
echo "Usage: ./strip.sh <Image File> <Last Partition #>"
exit
fi

if [[ ! -e $1 || ! $(file $1) =~ "DOS/MBR" ]]; then
echo "Error : Not an image file, or file doesn't exist"
exit
fi

echo "This will truncate '$1'.  Press Enter to continue."
read -s

origsize=`stat -c "%s" $1`

part1=`/sbin/parted $1 rm $(( $2 + 1))-10`
endresult=`/sbin/parted -m $1 unit B print free | tail -1 | awk -F: ' { print substr($2,0,length($2)-1) } '`
truncate -s $endresult $1

echo "Original Image Size: $origsize"
echo "New Image Size: $endresult"
