#!/bin/bash

# If you make a symlink to this script from a directory in your PATH and call
# it "foo", then;
#    DISPLAY=$ALCATRAZ_DISPLAY \
#    foo arg1 arg2
#
# will achieve the same thing as;
#    DISPLAY=$ALCATRAZ_DISPLAY \
#    ARG_RUN_ARBITRARY="foo arg1 arg2" \
#    make -C ~/alcatraz alcatraz_run-arbitrary
#
# Implied is that you should have already set ALCATRAZ_DISPLAY to whichever
# x-server you want alcatrazzed apps to hit.

DISPLAY=$ALCATRAZ_DISPLAY ARG_RUN_ARBITRARY="`basename $0` $@" make -C ~/alcatraz alcatraz_run-arbitrary
