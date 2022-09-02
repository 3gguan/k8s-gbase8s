#!/bin/bash

SCRIPTS_DIR=/scripts

FILE=$1
if [ ! -n "$FILE" ]; then
  echo "need file path"
  exit 0
fi

if [ -f $FILE ]; then
  source $SCRIPTS_DIR/env.sh
  echo "0" > $SCRIPTS_DIR/check.conf
  onmode -ky
  cat $FILE | ontape -p -t STDIO
  echo "1" > $SCRIPTS_DIR/check.conf
else
  echo "file not exists"
fi
