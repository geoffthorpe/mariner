#!/bin/bash

set -e

function usage() {
	echo
	echo "Usage:  make  <image>_launch"
	echo "Environment variables as arguments:"
	echo "    ARG_DISKIMAGE = <file name>"
	echo "    ARG_DISKPATH = <path>"
	echo "    ARG_NOGRAPHIC = <empty | non-empty>   (default: empty, use a GUI)"
	echo
	echo "Note, this uses two of the same parameters used for the '_mkdiskimage' tool,"
	echo "and interprets them in the same way. E.g. kernel and ramdisk are expected at"
	echo "the same path as the disk image, and with the same name suffixed by"
	echo "'.vmlinuz' and '.initrd.img' respectively."
	echo
}

# If running as root, whine
if [ "`whoami`" == "root" ]; then
	echo "Bad: running as root, please drop privs"
	usage
	exit 1
fi

if [ "x$ARG_DISKIMAGE" == "x" -o "x$ARG_DISKPATH" == "x" ]; then
	echo "Bad: missing arguments"
	usage
	exit 1
fi

OUTPUT_DISK=$ARG_DISKPATH/$ARG_DISKIMAGE

echo "Creating an ephemeral CoW overlay on read-only (root-owned) rootfs"
qemu-img create -b $OUTPUT_DISK -f qcow2 tmp.qcow2
if [ "x$ARG_NOGRAPHIC" == "x" ]; then
	qemu-system-x86_64 -drive file=tmp.qcow2 -m 1024 \
		-kernel $OUTPUT_DISK.vmlinuz -initrd $OUTPUT_DISK.initrd.img \
		-serial stdio -append "root=/dev/sda1 console=ttyS0"
else
	qemu-system-x86_64 -drive file=tmp.qcow2 -m 1024 \
		-kernel $OUTPUT_DISK.vmlinuz -initrd $OUTPUT_DISK.initrd.img \
		-nographic -append "root=/dev/sda1 console=ttyS0"
fi
