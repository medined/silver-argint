#!/bin/bash

# cert-manager introduces certificate authorities and certificates as 
# first-class resource types in k8s. This makes it possible to provide 
# 'certificates as a service' to developers working within your k8s cluster.
#

if [ $# -ne 2 ]; then
  echo "Usage: -f [configuration file] <namespace>"
  echo "  only $# parameters were provided."
  exit
fi

if [ "$1" != "-f" ]; then
    echo "ERROR: Expecting -f parameter."
    exit
fi

unset ACME_REGISTRATION_EMAIL

CONFIG_FILE=$2

if [ ! -f $CONFIG_FILE ]; then
    echo "ERROR: Missing configuration file: $CONFIG_FILE"
    return
fi
source $CONFIG_FILE

if [ -z $ACME_REGISTRATION_EMAIL ]; then
  echo "ERROR: Missing environment variable: ACME_REGISTRATION_EMAIL"
  exit
fi

SERVICE="cert-manager"
NAMESPACE=cert-manager

kubectl apply -f - <<EOF
apiVersion: v1
kind: Namespace
metadata:
    name: $NAMESPACE
    labels:
        name: $NAMESPACE
EOF

# Add the helm repository.
helm repo add jetstack https://charts.jetstack.io

# Install the chart if needed.
helm list --namespace $NAMESPACE | grep $SERVICE > /dev/null
if [ $? != 0 ]; then
    helm install $SERVICE jetstack/cert-manager --version v0.13.0 --namespace $NAMESPACE --set webhook.enabled=false
    echo "Helm chart installed: $SERVICE"
else
    echo "Helm chart exists: $SERVICE"
fi

echo "Waiting 30 seconds for resources to spin up. Adjust as needed."
sleep 30

cat <<EOF > yaml/certificate-issuer.yaml
apiVersion: cert-manager.io/v1alpha2
kind: Issuer
metadata:
  name: letsencrypt-development-issuer
  namespace: cert-manager
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
  namespace: cert-manager
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
kubectl apply -f yaml/certificate-issuer.yaml
