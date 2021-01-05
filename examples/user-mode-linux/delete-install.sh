#!/bin/bash

set -e

if [ ! -d /install_uml ]; then
	echo "No bind-mount for /install_uml";
	exit 1
fi

echo "[delete-install] begin..."
rm -r /install_uml/*

if [ -d /source_uml ]; then
	cd /source_uml
	rm -f success.install
fi

echo "[delete-install] success!"
