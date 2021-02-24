#!/bin/bash

set -e

echo "Adding group account ($FEATURE_HAS_MY_USER_GNAME,$FEATURE_HAS_MY_USER_GID)"
addgroup --gid $FEATURE_HAS_MY_USER_GID $FEATURE_HAS_MY_USER_GNAME

echo "Adding user account ($FEATURE_HAS_MY_USER_NAME,$FEATURE_HAS_MY_USER_UID,$FEATURE_HAS_MY_USER_GECOS)"
adduser --uid $FEATURE_HAS_MY_USER_UID --gid $FEATURE_HAS_MY_USER_GID --disabled-password --gecos "$FEATURE_HAS_MY_USER_GECOS" $FEATURE_HAS_MY_USER_NAME

for i in $FEATURE_HAS_MY_USER_GROUPS; do
	echo "Adding user ($FEATURE_HAS_MY_USER_NAME) to group ($i)"
	adduser $FEATURE_HAS_MY_USER_NAME $i || echo "failed, ignoring"
done

echo "Giving user ($FEATURE_HAS_MY_USER_NAME) sudo privs"
echo "$FEATURE_HAS_MY_USER_NAME ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/mariner-embed-me
chmod 0440 /etc/sudoers.d/mariner-embed-me
