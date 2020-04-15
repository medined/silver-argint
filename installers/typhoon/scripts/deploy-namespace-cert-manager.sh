#!/bin/bash

kubectl apply -f - <<EOF
apiVersion: v1
kind: Namespace
metadata:
    name: cert-manager
    labels:
        name: cert-manager
EOF

kubectl apply --validate=false -f https://github.com/jetstack/cert-manager/releases/download/v0.14.1/cert-manager.crds.yaml

helm repo add jetstack https://charts.jetstack.io

helm list --namespace cert-manager | grep cert-manager > /dev/null
if [ $? != 0 ]; then
    helm install cert-manager jetstack/cert-manager --version v0.14.1 --namespace cert-manager
    echo "Helm chart installed: cert-manager"
else
    echo "Helm chart exists: cert-manager"
fi

# wait for resources to start.
sleep 10

kubectl apply -f - <<EOF
apiVersion: cert-manager.io/v1alpha2
kind: ClusterIssuer
metadata:
  name: letsencrypt-staging
spec:
  acme:
    email: dmedined@crimsongovernment.com
    server: https://acme-staging-v02.api.letsencrypt.org/directory
    privateKeySecretRef:
      name: letsencrypt-staging-secret
    solvers:
    - http01:
        ingress:
          class: nginx
---
apiVersion: cert-manager.io/v1alpha2
kind: ClusterIssuer
metadata:
  name: letsencrypt-production
spec:
  acme:
    email: dmedined@crimsongovernment.com
    server: https://acme-v02.api.letsencrypt.org/directory
    privateKeySecretRef:
      name: letsencrypt-production-secret
    solvers:
    - http01:
        ingress:
          class: nginx
EOF
