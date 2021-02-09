#!/bin/bash

set -e

cd $HOME

if [ ! -f success-vde.clone ]; then
	echo "[git clone] needs doing"
	if [ -d vde-2 ]; then
		echo "[git clone] clean out old dregs first"
		rm -rf vde-2
	fi

	echo "[git clone] begin..."
	git clone https://github.com/virtualsquare/vde-2.git
	echo "[git clone] success-vde!"
	touch success-vde.clone
else
	echo "[git update] begin..."
	(cd vde-2 && git pull)
	echo "[git update] success-vde!"
fi

if [ ! -f success-vde.build ]; then
	echo "[build] begin..."
	(cd vde-2 && autoreconf --install &&
	./configure --prefix=/install --enable-static --disable-shared &&
	make)
	echo "[build] success-vde!"
	touch success-vde.build
else
	echo "[rebuild] begin..."
	(cd vde-2 && make)
	echo "[rebuild] success-vde!"
	touch success-vde.build
fi

echo "[install] begin..."
(cd vde-2 && sudo make install)
echo "[install] success-vde!"
touch success-vde.install
