#!/bin/bash

#创建configMap，用于配置卷
kubectl create configmap gbase8s-primary-conf --from-file=../../docker/conf/primary

#创建secret，用于gbasedbt密码
kubectl create secret generic gbase8s-primary-secret --from-literal=password=gbasedbt123

kubectl create -f primary.yaml


kubectl create configmap gbase8s-secondary-conf --from-file=../../docker/conf/secondary
kubectl create secret generic gbase8s-secondary-secret --from-literal=password=gbasedbt123
kubectl create -f secondary.yaml
