#!/bin/bash

# Source: https://www.howtouselinux.com/post/quick-guide-to-deploy-postgresql-in-a-kubernetes-env

kubectl create ns htul
kubectl apply -f sc.yaml -n htul
kubectl apply -f pv.yaml -n htul
kubectl apply -f pvc.yaml -n htul
kubectl apply -f statefulset.yaml -n htul
kubectl apply -f service.yaml -n htul
