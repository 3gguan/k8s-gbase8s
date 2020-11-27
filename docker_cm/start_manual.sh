#!/bin/bash

su gbasedbt -c "oncmsm -c $GBASEDBTDIR/etc/cfg.cm"
echo "1" > check.conf
