#!/bin/bash

su gbasedbt -c "oncmsm -c $GBASEDBTDIR/etc/cfg.cm" &>/dev/null
echo "1" > check.conf
