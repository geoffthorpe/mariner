#!/bin/bash

set -e

echo

function usage() {
	echo
	echo "Usage:  make  <image>_mkdiskimage"
	echo
	echo "Environment variables as arguments:"
	echo "    ARG_DOCKERIMAGE = <docker image name>  (to be converted into a disk image)"
	echo "    ARG_DISKIMAGE = <output file name>     (for the resulting disk image)"
	echo "    ARG_DISKSIZE = <number of bytes>       (in any format accepted by 'dd')"
	echo "    ARG_DISKPATH = <path for output>"
	echo
	echo "Note, it makes sense to mount a persistent volume to the container and ensure"
	echo "ARG_DISKPATH is a path within that mount. Otherwise, the conversion and output"
	echo "will occur, but will then disappear when the container exits."
	echo
	echo "Note also, we extract the kernel and ramdisk from the filesystem and copy them"
	echo "together with the diskimage (and to the same path). These are given '.vmlinuz'"
	echo "and '.initrd.img' suffixes relative to ARG_DISKIMAGE. The '_launch' tool uses"
	echo "the same file-naming assumption to run qemu against the resulting output."
	echo
}

# If not running as root, whine
if [ "`whoami`" != "root" ]; then
	echo "Bad: running as '`whoami`', need to be running as root"
	exit 1
fi

if [ "x$ARG_DOCKERIMAGE" == "x" -o "x$ARG_DISKIMAGE" == "x" -o "x$ARG_DISKSIZE" == "x" -o "x$ARG_DISKPATH" == "x" ]; then
	echo "Bad: missing arguments"
	usage
	exit 1
fi

OUTPUT_DISK=$ARG_DISKPATH/$ARG_DISKIMAGE

echo "Creating a blank/zero file '$OUTPUT_DISK' of size '$ARG_DISKSIZE'"
dd if=/dev/zero of=$OUTPUT_DISK bs=$ARG_DISKSIZE count=1

echo "Setting up a partition table, one partition at offset 2048 sectors"
echo "(512 bytes per sector, so that's 1Mb)"
sfdisk $OUTPUT_DISK <<EOF
label: dos
label-id: 0xdeadbeef
unit: sectors

linux-part : start=2048, type=83, bootable
EOF

echo "Exporting '$ARG_DOCKERIMAGE' container image to tarball..."
CID=$(docker run -d $ARG_DOCKERIMAGE /bin/true)
docker export -o /extracted.tar ${CID}
docker container rm -f ${CID}
ls -l /extracted.tar

echo "Set up a loop device for '$OUTPUT_DISK', at 1M offset"
losetup -o 1048576 /dev/loop0 $OUTPUT_DISK
echo "Formatting ext3 partition through loop"
mkfs.ext3 /dev/loop0
echo "Mounting ext3 partition"
mkdir /mount-os
mount -t auto /dev/loop0 /mount-os
echo "Extracting tarball into ext3 partition"
tar -xf /extracted.tar -C /mount-os
echo "Installing bootloader into /boot"
extlinux --install /mount-os/boot/
cat > /mount-os/boot/syslinux.cfg <<EOF
DEFAULT linux
  SAY Now booting the kernel from SYSLINUX...
 LABEL linux
  KERNEL /vmlinuz
  APPEND ro root=/dev/sda1 initrd=/initrd.img
EOF
echo "Installing MBR (Master Boot Record) into disk image"
dd if=/usr/lib/syslinux/mbr/mbr.bin of=$OUTPUT_DISK bs=440 count=1 conv=notrunc
echo "Copying kernel and ramdisk to '$OUTPUT_DISK.{vmlinuz,initrd.img}'"
cp /mount-os/vmlinuz $OUTPUT_DISK.vmlinuz
cp /mount-os/initrd.img $OUTPUT_DISK.initrd.img
echo "Unmounting and releasing the loop device"
umount /mount-os
losetup -D
echo "Done, results at '$OUTPUT_DISK*';"
ls -l $OUTPUT_DISK*
