#!/bin/bash

#docker run -d --name=8s --privileged=true -p9088:9088 gbase8s:8.8
#docker run -d --name=8s --privileged=true -v/root/k8s/gbase8s/A2_server/data:/opt/gbase8s/storage -v/root/k8s/gbase8s/A2_server/logs:/opt/gbase8s/logs gbase8s:8.8

docker rm -f 8s-0 8s-1 8s-2 8s-3 cm

docker run -d --name=8s-0 --privileged=true -p9088:9088 -p8000:8000 -v/root/work/k8s-gbase8s/docker/server:/server -v/root/work/k8s-gbase8s/docker/conf/rss0:/conf -v/root/work/k8s-gbase8s/docker/server:/server -e SERVER_TYPE=primary -e ONCONFIG_FILE_NAME=/conf/onconfig.ol_gbasedbt_1 -e SQLHOSTS_FILE_NAME=/conf/sqlhosts.ol_gbasedbt_1 gbase8s:8.8

docker run -d --name=8s-1 --privileged=true -p9089:9088 -p8001:8000 -v/root/work/k8s-gbase8s/docker/entrypoint.sh:/entrypoint.sh -v/root/work/k8s-gbase8s/docker/conf/rss1:/conf -e ONCONFIG_FILE_NAME=/conf/onconfig.ol_gbasedbt_1 -e SQLHOSTS_FILE_NAME=/conf/sqlhosts.ol_gbasedbt_1 -e SERVER_TYPE=secondary -e PRIMARY_SERVER_NAME=rss0 gbase8s:8.8

docker run -d --name=8s-2 --privileged=true -p9090:9088 -p8002:8000 -v/root/work/k8s-gbase8s/docker/entrypoint.sh:/entrypoint.sh -v/root/work/k8s-gbase8s/docker/conf/rss2:/conf -e ONCONFIG_FILE_NAME=/conf/onconfig.ol_gbasedbt_1 -e SQLHOSTS_FILE_NAME=/conf/sqlhosts.ol_gbasedbt_1 -e SERVER_TYPE=secondary -e PRIMARY_SERVER_NAME=rss0 gbase8s:8.8

docker run -d --name=8s-3 --privileged=true -p9091:9088 -p8003:8000 -v/root/work/k8s-gbase8s/docker/entrypoint.sh:/entrypoint.sh -v/root/work/k8s-gbase8s/docker/conf/rss3:/conf -e ONCONFIG_FILE_NAME=/conf/onconfig.ol_gbasedbt_1 -e SQLHOSTS_FILE_NAME=/conf/sqlhosts.ol_gbasedbt_1 -e SERVER_TYPE=secondary -e PRIMARY_SERVER_NAME=rss0 gbase8s:8.8

docker run -d --name=cm --privileged=true -p9910:9910 -v/root/work/k8s-gbase8s/docker/conf/cm1/sqlhost.cm1:/opt/gbase8s/etc/sqlhost.cm1 -v /root/work/k8s-gbase8s/docker/conf/cm1/cfg.cm1:/opt/gbase8s/etc/cfg.cm1 gbase8s:8.8

