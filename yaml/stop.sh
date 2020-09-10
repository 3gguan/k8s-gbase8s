#!/bin/bash

kubectl delete -f gbase8s.yaml

kubectl delete configmap gbase8s-conf

kubectl delete secret gbase8s-secret
