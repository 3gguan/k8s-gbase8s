#!/bin/bash

GBASE_VER=`cat version`
COMMIT_ID=`git rev-parse --short HEAD`
VER=$GBASE_VER"_"$COMMIT_ID

docker build --label BuildVer=$VER -t gbase8s_test:8.8 .
