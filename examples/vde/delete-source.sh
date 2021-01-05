#!/bin/bash

set -e

if [ ! -d /source_vde ]; then
	echo "No bind-mount for /source_vde";
	exit 1
fi

echo "[delete-source] begin..."
rm -r /source_vde/*
echo "[delete-source] success!"
