#!/bin/bash

set -e

cd $HOME

if [ ! -f success-openssl.clone ]; then
	echo "[git clone] needs doing"
	if [ -d openssl ]; then
		echo "[git clone] clean out old dregs first"
		rm -rf openssl
	fi

	echo "[git clone] begin..."
	git clone https://github.com/openssl/openssl.git
	echo "[git clone] success-openssl!"
	touch success-openssl.clone
else
	echo "[git update] begin..."
	(cd openssl && git pull)
	echo "[git update] success-openssl!"
fi

if [ ! -f success-openssl.build ]; then
	echo "[build] begin..."
	(cd openssl &&
	./Configure --prefix=/install --openssldir=/install/ssl &&
	make)
	echo "[build] success-openssl!"
	touch success-openssl.build
else
	echo "[rebuild] begin..."
	(cd openssl && make)
	echo "[rebuild] success-openssl!"
	touch success-openssl.build
fi

echo "[install] begin..."
(cd openssl && sudo make install)
echo "[install] success-openssl!"
touch success-openssl.install
