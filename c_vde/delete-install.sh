#!/bin/bash

set -e

if [ ! -d /install_vde ]; then
	echo "No bind-mount for /install_vde";
	exit 1
fi

echo "[delete-install] begin..."
rm -r /install_vde/*

if [ -d /source_vde ]; then
	cd /source_vde
	rm -f success.install
fi

echo "[delete-install] success!"
