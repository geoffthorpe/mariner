#!/bin/bash

set -e

if [ ! -d /source_vde ]; then
	echo "No bind-mount for /source_vde";
	exit 1
fi
if [ ! -d /install_vde ]; then
	echo "No bind-mount for /install_vde";
	exit 1
fi

cd /source_vde

if [ ! -f success.clone ]; then
	echo "[git clone] needs doing"
	if [ -d vde-2 ]; then
		echo "[git clone] clean out old dregs first"
		rm -rf vde-2
	fi

	# Provide a way to specify an optional prefix, e.g. for wrappers that
	# set http_proxy and so forth.
	echo "[git clone] begin..."
	git clone https://github.com/virtualsquare/vde-2.git
	echo "[git clone] success!"
	touch success.clone
else
	echo "[git update] begin..."
	(cd vde-2 && git pull)
	echo "[git update] success!"
fi

if [ ! -f success.build ]; then
	echo "[build] begin..."
	cd vde-2
	autoreconf --install
	./configure --prefix=/install_vde \
		--enable-static --disable-shared
	make
	make install
	cd ..
	echo "[build] success!"
	touch success.build
else
	echo "[rebuild] begin..."
	cd vde-2
	make
	make install
	cd ..
	echo "[rebuild] success!"
	touch success.build
fi

echo "[install] begin..."
cd vde-2
make install
cd ..
echo "[install] success!"
touch success.install
