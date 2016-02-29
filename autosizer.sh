#!/bin/bash
# Automatic Image file resizer
# Shamelessly stolen and modified by "David A. Russell" <david@aprsworld.com>
#
# This script will shrink an image file with a single FAT32 partition followed by
# a single ext4 partition.  It will shrink the ext4 partition found to the minimum
# size required to exist with all files + the second argument in MegaBytes for spare
# space.
#
# Example:  You have an image file with a single ext4 partition that you want
# resized to be the minimum size it can plus 100MB - ./autosizer.sh <imagefile> 100
#
# It assumes partition 1 is the FAT32 boot partition and 2 is the ext4 partition.
# It is also destructive and will modify the original file!!!
#
strImgFile=$1
extraSpace=$2

if [[ ! $(whoami) =~ "root" ]]; then
echo ""
echo "**********************************"
echo "*** This should be run as root ***"
echo "**********************************"
echo ""
exit
fi

if [[ -z $1 ]]; then
echo "Usage: ./autosizer.sh <Image File> [<extraSpace>]"
exit
fi

if [[ ! -e $1 || ! $(file $1) =~ "DOS/MBR" ]]; then
echo "Error : Not an image file, or file doesn't exist"
exit
fi

extraSpace=$(( extraSpace * 1048576 ))

partinfo=`parted -m $1 unit B print`
partnumber=`echo "$partinfo" | grep ext4 | awk -F: ' { print $1 } '`
partstart=`echo "$partinfo" | grep ext4 | awk -F: ' { print substr($2,0,length($2)-1) } '`
loopback=`losetup -f --show -o $partstart $1`
e2fsck -f $loopback
minsize=`resize2fs -P $loopback | awk -F': ' ' { print $2 } '`
minsize=`echo $minsize+1000 | bc`
minsize=$(( $minsize + $extraSpace ))
resize2fs -p $loopback $minsize
sleep 1
losetup -d $loopback
partnewsize=`echo "$minsize * 4096" | bc`
newpartend=`echo "$partstart + $partnewsize" | bc`
part1=`parted $1 rm 2`
part2=`parted $1 unit B mkpart primary $partstart $newpartend`
endresult=`parted -m $1 unit B print free | tail -1 | awk -F: ' { print substr($2,0,length($2)-1) } '`
truncate -s $endresult $1
