#!/bin/bash

# cert-manager introduces certificate authorities and certificates as 
# first-class resource types in k8s. This makes it possible to provide 
# 'certificates as a service' to developers working within your k8s cluster.
#

NAMESPACE=${1:-sandbox}
ACME_REGISTRATION_EMAIL=${2:-'dmedined@crimsongovernment.com'}
SERVICE="cert-manager"

./namespace-create.sh

# Add the helm repository.
helm repo add jetstack https://charts.jetstack.io

# Install the chart if needed.
helm list --namespace kube-system | grep $SERVICE > /dev/null
if [ $? != 0 ]; then
    helm install $SERVICE jetstack/cert-manager --version v0.13.0 --namespace kube-system
    echo "Helm chart installed: $SERVICE"
else
    echo "Helm chart exists: $SERVICE"
fi

cat <<EOF > yaml/certificate-issuer.yaml
apiVersion: cert-manager.io/v1alpha2
kind: Issuer
metadata:
  name: letsencrypt-development-issuer
  namespace: $NAMESPACE
spec:
  acme:
    # The ACME server URL
    server: https://acme-staging-v02.api.letsencrypt.org/directory
    email: $ACME_REGISTRATION_EMAIL
    # Name of a secret used to store the ACME account private key
    privateKeySecretRef:
      name: letsencrypt-development-issuer
    # Enable the HTTP-01 challenge provider
    solvers:
    - http01:
        ingress:
          class: nginx
---
apiVersion: cert-manager.io/v1alpha2
kind: Issuer
metadata:
  name: letsencrypt-production-issuer
  namespace: $NAMESPACE
spec:
  acme:
    # The ACME server URL
    server: https://acme-v02.api.letsencrypt.org/directory
    # Email address used for ACME registration
    email: $ACME_REGISTRATION_EMAIL
    # Name of a secret used to store the ACME account private key
    privateKeySecretRef:
      name: letsencrypt-production-issuer
    # Enable the HTTP-01 challenge provider
    solvers:
    - http01:
        ingress:
          class: nginx
EOF
kubectl create -f yaml/certificate-issuer.yaml
