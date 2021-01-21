#!/bin/bash

GBASE_VER=`cat version`
COMMIT_ID=`git rev-parse --short HEAD`
VER=$GBASE_VER_$COMMIT_ID

docker build --label=$VER -t gbase8s:8.8 .
