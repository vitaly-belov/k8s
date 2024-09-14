#!/bin/bash

# Source: https://pcnews.ru/blogs/%5Bperevod%5D_kak_razvernut_postgresql_v_kubernetes-1265850.html#gsc.tab=0

kubectl create namespace database-demo
kubectl apply -f pv-db.yml -n database-demo
kubectl get pv -n database-demo
kubectl apply -f pvc-db.yml -n database-demo
kubectl get pvc -n database-demo
kubectl apply -f cm-db.yml -n database-demo
kubectl get cm -n database-demo
kubectl apply -f secret-db.yml -n database-demo
kubectl get secret -n database-demo
kubectl apply -f deployment-db.yml -n database-demo
kubectl get deploy -n database-demo
kubectl apply -f svc-db.yml -n database-demo
kubectl get svc -n database-demo
# kubectl exec -it deployment-db-7b87c6f554-8kvxl -n database-demo -- psql -h localhost -U admin --password -p 5432 gifts-table
