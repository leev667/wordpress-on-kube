#!/bin/bash

#First volumes must be prepared to offer persistent volumes, nfs for webshares and one central offering for the MySQLDB
#example
#df -PhT {/var/www/html,/var/lib/mysql}
#Filesystem                     Type  Size  Used Avail Use% Mounted on
#10.0.0.114:/web-shares         nfs4   49G  1.5G   48G   4% /var/www/html
#/dev/mapper/mysqlDB-mysqlDB_lv xfs    20G  384M   20G   2% /var/lib/mysql

####################################################
#Clean up

#svc
kubectl delete svc my-wordpress
kubectl delete svc wordpress-mysql

#deployments
kubectl delete deployment wordpress
kubectl delete deployment wordpress-mysql

#persistentvolumeclaims, persistent volumes
kubectl delete pvc wp-pv-claim
kubectl delete pvc mysql-pv-claim
kubectl delete pv mysql-vol 
kubectl delete pv wordpress-nfs-vol

#################################################
#Re-create
#Create Kustom file
cat <<EOF >./kustomization.yaml
secretGenerator:
- name: mysql-pass
  literals:
  - password=+FT[gJ}BO"pgLOC}hu6ckRjn<
EOF

#Apply

#Add the configs to the Kustom
cat <<EOF >>./kustomization.yaml
resources:
  - mysql-deployment.yaml
  - wordpress-deployment.yaml
EOF

#Create Persistent Volumes
kubectl create -f mysql-volume.yaml
kubectl create -f wordpress-nfsvolume.yaml

#Apply config
kubectl apply -k ./
kubectl get secrets

#Expose with LB
kubectl expose deployment wordpress --type=LoadBalancer --name=my-wordpress

#Configure main interface as external IP to Load Balancer
kubectl patch svc my-wordpress -p '{"spec": {"type": "LoadBalancer", "externalIPs":["10.0.1.72"]}}'

#Scale up web containers
kubectl scale deployment wordpress --replicas=3
