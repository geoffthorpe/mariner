#!/bin/bash

if [ "x$COUNTER_VAL" == "x" ]; then
	COUNTER_VAL=10
fi

SEQ=`seq $COUNTER_VAL -1 1`

for i in $SEQ; do
	echo $i
	sleep 1
done
