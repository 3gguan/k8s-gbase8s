#!/bin/bash

FILE=$1
if [ ! -n "$FILE" ]; then
  echo "need file path"
  exit 0
fi

if [ -f $FILE ]; then
  source /env.sh
  echo "0" > /check.conf
  onmode -ky
  cat $FILE | ontape -p -t STDIO
  echo "1" > /check.conf
else
  echo "file not exists"
fi
