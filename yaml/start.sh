#!/bin/bash

#创建configMap，用于配置卷
kubectl create configmap gbase8s-conf --from-file=../docker/conf/single

#创建secret，用于gbasedbt密码
kubectl create secret generic gbase8s-secret --from-literal=password=gbasedbt123

kubectl create -f gbase8s.yaml
