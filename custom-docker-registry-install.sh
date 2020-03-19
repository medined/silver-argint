#!/bin/bash

# This script installs a custom docker registry into k8s.
#  https://www.nearform.com/blog/how-to-run-a-custom-docker-registry-in-kubernetes/
#
# GOAL:
#   curl -u user:pass https://registry.va-oit.cloud/v2/catalog

if [ $# -ne 3 ]; then
  echo "Usage: -f [configuration file] <namespace>"
  exit
fi

if [ "$1" != "-f" ]; then
    echo "ERROR: Expecting -f parameter."
    exit
fi

unset ACME_REGISTRATION_EMAIL
unset DOMAIN_NAME

CONFIG_FILE=$2
NAMESPACE=$3
source $CONFIG_FILE

if [ -z $DOMAIN_NAME ]; then
  echo "ERROR: Missing environment variable: DOMAIN_NAME"
  return
fi

SERVICE_NAME=registry
REGISTRY_HOST="$SERVICE_NAME.$DOMAIN_NAME"
ISSUER="letsencrypt-production-issuer"

# Does the hosted zone exist?

export HOSTED_ZONE_ID=$(aws route53 list-hosted-zones-by-name --query "HostedZones[?Name==\`$DOMAIN_NAME.\`].Id" --output text)
if [ -z $HOSTED_ZONE_ID ]; then
  echo "Domain [$DOMAIN_NAME] is missing from Route53."
  echo "This script only works with domains hosted by Route53."
  exit
else
  echo "Hosted Zone exists: $DOMAIN_NAME - $HOSTED_ZONE_ID"
fi

# Does the sub-domain exist?

ENTRY=$(aws route53 list-resource-record-sets \
  --hosted-zone-id $HOSTED_ZONE_ID \
  --query "ResourceRecordSets[?(Name==\`$REGISTRY_HOST.\` && Type==\`CNAME\`)].Name" \
  --output text)
if [ -z $ENTRY ]; then
  echo "ERROR: Vanity domain missing: - $REGISTRY_HOST"
  exit
else
  echo "Vanity domain exists: $REGISTRY_HOST"
fi

# Does the namespace exist?

kubectl get namespace $NAMESPACE 1>/dev/null 2>&1
if [ $? != 0 ]; then
    echo "ERROR: Missing namespace: $NAMESPACE"
    echo "  Please run ./namespace-create.sh"
    exit
else
    echo "Namespace exists: $NAMESPACE"
fi

# Does the issuer exist?

kubectl get issuer $ISSUER 1>/dev/null 2>&1
if [ $? != 0 ]; then
    echo "ERROR: Missing issuer: $ISSUER"
    echo "  Please run ./cert-manager-install.sh"
    exit
else
    echo "Issuer exists: $ISSUER"
fi

cat <<EOF > yaml/registry-certificate.yaml
apiVersion: cert-manager.io/v1alpha2
kind: Certificate
metadata:
  name: docker-registry
  namespace: $NAMESPACE
spec:
  secretName: docker-registry-tls-certificate
  issuerRef:
    name: $ISSUER
  dnsNames:
  - $REGISTRY_HOST
EOF
kubectl apply -f yaml/registry-certificate.yaml

# The following command can be used for debugging.
# kubectl describe certificate docker-registry --namespace=$NAMESPACE

# This script uses two secrets. One to hold the password for people to login 
# with. And the other for the container to hold to authenticate with.

# This password is used two ways. One is passed into the container encrypted
# using HTPASSWD which can't be recovered as clear text. The other is intended
# to be used by a docker login script.

kubectl get secret docker-registry-admin-password 1>/dev/null 2>&1
if [ $? == 0 ]; then
    echo "Registry password secret exists."
    PASSWORD=$(kubectl get secret --namespace $NAMESPACE docker-registry-admin-password -o jsonpath="{.data.password}" | base64 --decode)
else
    PASSWORD=$(uuid)
    # Note that yaml files are not written so that the password is never stored locally.

    kubectl apply -f - <<EOF
apiVersion: v1
kind: Secret
type: Opaque
metadata:
    name: docker-registry-admin-password
    namespace: $NAMESPACE
data:
    password: $(echo $PASSWORD | base64)
EOF
fi

kubectl get secret docker-registry-htpasswd 1>/dev/null 2>&1
if [ $? == 0 ]; then
    echo "Registry htpasswd secret exists."
else
    docker pull registry:2
    HTPASSWORD=$(docker run --entrypoint htpasswd --rm registry:2 -Bbn admin $PASSWORD | base64 --wrap 92)

    kubectl apply -f - <<EOF
apiVersion: v1
kind: Secret
type: Opaque
metadata:
    name: docker-registry-htpasswd
    namespace: $NAMESPACE
data:
    HTPASSWD: $HTPASSWORD
EOF
fi

# Create a configuration map where the authentication method is defined to be Basic Auth.

cat <<EOF > yaml/registry-config-map.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: docker-registry
  namespace: $NAMESPACE
data:
  registry-config.yml: |
    version: 0.1
    log:
      fields:
        service: registry
    storage:
      cache:
        blobdescriptor: inmemory
      filesystem:
        rootdirectory: /var/lib/registry
    http:
      addr: :5000
      headers:
        X-Content-Type-Options: [nosniff]
    auth:
      htpasswd:
        realm: basic-realm
        path: /auth/htpasswd
    health:
      storagedriver:
        enabled: true
        interval: 10s
        threshold: 3
EOF
kubectl apply -f yaml/registry-config-map.yaml

# Define pod.

cat <<EOF > yaml/registry-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: docker-registry
  namespace: $NAMESPACE
  labels:
    name: docker-registry
spec:
  volumes:
    - name: config
      configMap:
        name: docker-registry
        items:
          - key: registry-config.yml
            path: config.yml
    - name: htpasswd
      secret:
        secretName: docker-registry-htpasswd
        items:
        - key: HTPASSWD
          path: htpasswd
    - name: storage
      emptyDir: {}
  containers:
    - name: docker-registry
      image: registry:2.6.2
      imagePullPolicy: IfNotPresent
      ports:
        - name: http
          containerPort: 5000
          protocol: TCP
      volumeMounts:
        - name: config
          mountPath: /etc/docker/registry
          readOnly: true
        - name: htpasswd
          mountPath: /auth
          readOnly: true
        - name: storage
          mountPath: /var/lib/registry
EOF
kubectl apply -f yaml/registry-pod.yaml

# Create a service.

cat <<EOF > yaml/registry-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: docker-registry
  namespace: $NAMESPACE
spec:
  type: ClusterIP
  ports:
    - name: http
      protocol: TCP
      port: 5000
      targetPort: 5000
  selector:
    name: docker-registry
EOF
kubectl apply -f yaml/registry-service.yaml

# Create an ingress.

cat <<EOF > yaml/registry-ingress.yaml
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: docker-registry
  namespace: $NAMESPACE
  annotations:
    kubernetes.io/ingress.class: nginx
    nginx.ingress.kubernetes.io/proxy-body-size: "0"
    certmanager.k8s.io/issuer: $ISSUER
spec:
  tls:
  - hosts:
    - $REGISTRY_HOST
    secretName: docker-registry-tls-certificate
  rules:
  - host: $REGISTRY_HOST
    http:
      paths:
      - backend:
          serviceName: docker-registry
          servicePort: 5000
EOF
kubectl apply -f yaml/registry-ingress.yaml

# Create a secret that allows k8s to pull from the
# newly created registry.

kubectl get secret docker-registry-credentials >/dev/null 2>&1
if [ $? == 0 ]; then
  echo "Secret exists: docker-registry-credentials"
else
  kubectl create secret docker-registry \
    docker-registry-credentials \
    --docker-server=$REGISTRY_HOST \
    --docker-username=admin \
    --docker-password=$PASSWORD
fi

# Note: The command below will retrieve and code the secret.
#
# kubectl get secret \
#   docker-registry-credentials \
#   --output="jsonpath={.data.\.dockerconfigjson}" | \
#   base64 --decode;echo

echo "----------------"
echo "The docker registry will soon be ready to accept requests. Please wait a few minutes."
echo 
