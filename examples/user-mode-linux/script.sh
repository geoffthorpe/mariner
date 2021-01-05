#!/bin/bash

set -e

export ARCH=um
export C_INCLUDE_PATH=/install_vde/include
export LIBRARY_PATH=/install_vde/lib

if [ ! -d /source_uml ]; then
	echo "No bind-mount for /source_uml";
	exit 1
fi
if [ ! -d /install_uml ]; then
	echo "No bind-mount for /install_uml";
	exit 1
fi

cd /source_uml

if [ ! -f success.clone ]; then
	echo "[git clone] needs doing"
	if [ -d linux-stable ]; then
		echo "[git clone] clean out old dregs first"
		rm -rf linux-stable
	fi

	echo "[git clone] begin..."
	git clone https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git
	echo "[git clone] success!"
	touch success.clone
else
	echo "[git update] begin..."
	(cd linux-stable && git pull)
	echo "[git update] success!"
fi

if [ ! -f success.build ]; then
	echo "[build] begin..."
	cd linux-stable
	make defconfig
	sed -i 's/# CONFIG_UML_NET_VDE is not set/CONFIG_UML_NET_VDE=y/' .config
	#sed -i 's/# CONFIG_BLK_DEV_INITRD is not set/CONFIG_BLK_DEV_INITRD=y/' .config
	make oldconfig
	make
	cd ..
	echo "[build] success!"
	touch success.build
else
	echo "[rebuild] begin..."
	cd linux-stable
	make
	cd ..
	echo "[rebuild] success!"
	touch success.build
fi

echo "[install] begin..."
cd linux-stable
install -m755 -Dt /install_uml/bin linux
INSTALL_MOD_PATH=/install_uml make modules_install
cd ..
echo "[install] success!"
touch success.install
