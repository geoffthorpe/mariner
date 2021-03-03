#!/bin/bash

# OK, so the idea is that the caller sets ARG_RUN_ARBITRARY, and calls
#      make alcatraz_run-arbitrary
#
# The container starts, the env-var is passed through, and this script runs.

echo "whoami=`whoami`"

echo "run-arbitrary:"
echo "   ARG_RUN_ARBITRARY=$ARG_RUN_ARBITRARY"
echo "   RUNFLAG_AS_ME=$RUNFLAG_AS_ME"
echo "   exec $RUNFLAG_AS_ME apulse $ARG_RUN_ARBITRARY"
exec $RUNFLAG_AS_ME apulse $ARG_RUN_ARBITRARY
