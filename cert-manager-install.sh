#!/bin/bash

# cert-manager introduces certificate authorities and certificates as 
# first-class resource types in k8s. This makes it possible to provide 
# 'certificates as a service' to developers working within your k8s cluster.
#

if [ $# -ne 3 ]; then
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
NAMESPACE=$3

if [ ! -f $CONFIG_FILE ]; then
    echo "ERROR: Missing configuration file: $CONFIG_FILE"
    return
fi
source $CONFIG_FILE

SERVICE="cert-manager"

if [ -z $ACME_REGISTRATION_EMAIL ]; then
  echo "ERROR: Missing environment variable: ACME_REGISTRATION_EMAIL"
  exit
fi
if [ -z $NAMESPACE ]; then
  echo "ERROR: Missing parameter: <namespace>"
  exit
fi

kubectl get namespace $NAMESPACE 1>/dev/null 2>&1
if [ $? != 0 ]; then
    echo "ERROR: Missing namespace: $NAMESPACE"
    echo "  Please run ./namespace-create.sh"
    exit
else
    echo "Namespace exists: $NAMESPACE"
fi

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

echo "Waiting 10 seconds for resources to spin up. Adjust as needed."
sleep 10

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
kubectl apply -f yaml/certificate-issuer.yaml
