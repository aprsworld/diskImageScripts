#!/bin/sh

disk=/dev/mmcblk0
part_type=fat32	# ext4 | fat32

### TODO: Alignment for optimal performance

# Calculate sizes
disk_size=$(/sbin/parted $disk -ms unit B print | head -n 2 | tail -n 1 | cut -d : -f 2 | sed s/B$//)
disk_size=$(( $disk_size - 1 ))
last_part=$(/sbin/parted $disk -ms unit B print | tail -n 1 | cut -d : -f 1)
if [ "$last_part" -ne 2 ]; then
	echo "Either less than or more than 2 partitions; Aborting."
	exit 0
fi
last_part_pos=$(/sbin/parted $disk -ms unit B print | tail -n 1 | cut -d : -f 3 | sed s/B$//)
last_part_pos=$(( $last_part_pos + 8 ))
diff=$(( $disk_size - $last_part_pos ))
if [ "$diff" -lt 1048576 ]; then
	echo "No space left for ancillary partition; Aborting."
	exit 0
fi

# Create Partition
echo "Creating partition..."
/sbin/parted $disk -ms unit B mkpart primary $part_type ${last_part_pos}B ${disk_size}B
if [ $? -ne 0 ]; then
	echo "$?"
	echo "Failed to create partition; Aborting."
	exit 1;
fi

# Create filesystem
echo "Creating filesystem..."
if [ $part_type = "fat32" ]; then
	fs_type="vfat"
else
	fs_type="$part_type"
fi
/sbin/mkfs.${fs_type} ${disk}p3
if [ $? -ne 0 ]; then
	echo "Failed to format partition; Removing..."
	/sbin/parted $disk -ms unit B rm 3
	exit 2;
fi
