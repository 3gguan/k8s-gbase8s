#!/bin/bash

kubectl delete -f primary.yaml

kubectl delete configmap gbase8s-primary-conf

kubectl delete secret gbase8s-primary-secret


kubectl delete -f secondary.yaml
kubectl delete configmap gbase8s-secondary-conf
kubectl delete secret gbase8s-secondary-secret
