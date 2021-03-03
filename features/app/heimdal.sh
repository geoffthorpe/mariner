#!/bin/bash

set -e

cd $HOME

export localbranch=my-7-1
export remotebranch=origin/heimdal-7-1-branch

if [ ! -f success-heimdal.clone ]; then
	echo "[git clone] needs doing"
	if [ -d heimdal ]; then
		echo "[git clone] clean out old dregs first"
		rm -rf heimdal
	fi

	echo "[git clone] begin..."
	git clone https://github.com/heimdal/heimdal.git
	echo "[git clone] success-heimdal!"
	touch success-heimdal.clone
else
	echo "[git update] begin..."
	(cd heimdal && git fetch origin && git merge $remotebranch)
	echo "[git update] success-heimdal!"
fi

if [ ! -f success-heimdal.build ]; then
	echo "[build] begin..."
	(cd heimdal &&
		git checkout -b $localbranch $remotebranch &&
		./autogen.sh &&
		./configure --prefix=/install --disable-otp &&
		make)
	echo "[build] success-heimdal!"
	touch success-heimdal.build
else
	echo "[rebuild] begin..."
	(cd heimdal && make)
	echo "[rebuild] success-heimdal!"
	touch success-heimdal.build
fi

echo "[install] begin..."
(cd heimdal && sudo make install)
echo "[install] success-heimdal!"
touch success-heimdal.install
