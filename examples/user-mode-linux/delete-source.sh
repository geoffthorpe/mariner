#!/bin/bash

set -e

if [ ! -d /source_uml ]; then
	echo "No bind-mount for /source_uml";
	exit 1
fi

echo "[delete-source] begin..."
rm -r /source_uml/*
echo "[delete-source] success!"
