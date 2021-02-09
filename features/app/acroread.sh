#!/bin/bash

set -e

fname=AdbeRdr9.5.5-1_i386linux_enu.deb
furl=ftp://ftp.adobe.com/pub/adobe/reader/unix/9.x/9.5.5/enu

if [ ! -f /$fname ]; then
	wget --no-verbose -O /$fname $furl/$fname
fi

dpkg -i /$fname

rm -f /$fname
