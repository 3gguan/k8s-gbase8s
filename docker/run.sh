#!/bin/bash

#docker run -d --name=8s --privileged=true -p9088:9088 gbase8s:8.8
#docker run -d --name=8s --privileged=true -v/root/k8s/gbase8s/A2_server/data:/opt/gbase8s/storage -v/root/k8s/gbase8s/A2_server/logs:/opt/gbase8s/logs gbase8s:8.8

docker rm -f 8s-p 8s-s

docker run -d --name=8s-p --privileged=true -p9088:9088 -p8000:8000 -v/root/work/k8s-gbase8s/docker/server:/server -v/root/work/k8s-gbase8s/docker/conf/primary:/conf -e ONCONFIG_FILE_NAME=/conf/onconfig.ol_gbasedbt_1 -e SQLHOSTS_FILE_NAME=/conf/sqlhosts.ol_gbasedbt_1 gbase8s:8.8
docker run -d --name=8s-s --privileged=true -p9089:9088 -p8001:8000 -v/root/work/k8s-gbase8s/docker/conf/secondary:/conf -e ONCONFIG_FILE_NAME=/conf/onconfig.ol_gbasedbt_1 -e SQLHOSTS_FILE_NAME=/conf/sqlhosts.ol_gbasedbt_1 gbase8s:8.8
