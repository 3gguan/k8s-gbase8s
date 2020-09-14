#!/bin/bash

#docker run -d --name=8s --privileged=true -v/root/k8s/gbase8s/A2_server/data:/opt/gbase8s/storage gbase8s:8.8
docker run -d --name=8s --privileged=true -v/root/k8s/gbase8s/A2_server/data:/opt/gbase8s/storage -v/root/k8s/gbase8s/A2_server/logs:/opt/gbase8s/logs gbase8s:8.8
