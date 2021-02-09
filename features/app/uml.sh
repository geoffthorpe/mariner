#!/bin/bash

set -e

cd $HOME

export ARCH=um
export C_INCLUDE_PATH=/install/include
export LIBRARY_PATH=/install/lib

if [ ! -f success-uml.clone ]; then
	echo "[git clone] needs doing"
	if [ -d linux-stable ]; then
		echo "[git clone] clean out old dregs first"
		rm -rf linux-stable
	fi

	echo "[git clone] begin..."
	git clone https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git
	echo "[git clone] success-uml!"
	touch success-uml.clone
else
	echo "[git update] begin..."
	(cd linux-stable && git pull)
	echo "[git update] success-uml!"
fi

if [ ! -f success-uml.build ]; then
	echo "[build] begin..."
	(cd linux-stable &&
	make defconfig &&
	sed -i 's/# CONFIG_UML_NET_VDE is not set/CONFIG_UML_NET_VDE=y/' .config &&
	make oldconfig &&
	make)
	echo "[build] success-uml!"
	touch success-uml.build
else
	echo "[rebuild] begin..."
	(cd linux-stable && make)
	echo "[rebuild] success-uml!"
	touch success-uml.build
fi

echo "[install] begin..."
(cd linux-stable && sudo install -m755 -Dt /install/bin linux &&
	INSTALL_MOD_PATH=/install sudo make modules_install)
echo "[install] success-uml!"
touch success-uml.install
