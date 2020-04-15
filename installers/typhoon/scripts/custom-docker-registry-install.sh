#!/bin/bash

# This script installs a custom docker registry into k8s.
#  https://www.nearform.com/blog/how-to-run-a-custom-docker-registry-in-kubernetes/
#
# GOAL:
#   curl -u user:pass https://registry.va-oit.cloud/v2/catalog

if [ -z $K8S_DOMAIN_NAME ]; then
  echo "Please set K8S_DOMAIN_NAME env variable. For example, david.va-oit.cloud"
  exit
fi
if [ -z $K8S_REGISTRY_NAMESPACE ]; then
  echo "Please set K8S_REGISTRY_NAMESPACE env variable. For example, custom-docker-registry"
  exit
fi
if [ -z $K8S_REGISTRY_SERVICE_NAME ]; then
  echo "Please set K8S_REGISTRY_SERVICE_NAME env variable. For example, registry"
  exit
fi

SERVICE_NAME=$K8S_REGISTRY_SERVICE_NAME
REGISTRY_HOST="$SERVICE_NAME.$K8S_DOMAIN_NAME"
ISSUER="letsencrypt-production"

# Does the hosted zone exist?

export HOSTED_ZONE_ID=$(aws route53 list-hosted-zones-by-name --query "HostedZones[?Name==\`$K8S_DOMAIN_NAME.\`].Id" --output text)
if [ -z $HOSTED_ZONE_ID ]; then
  echo "Domain [$K8S_DOMAIN_NAME] is missing from Route53."
  echo "This script only works with domains hosted by Route53."
  exit
else
  echo "Hosted Zone exists: $K8S_DOMAIN_NAME - $HOSTED_ZONE_ID"
fi

# Does the sub-domain exist?

ENTRY_CNAME=$(aws route53 list-resource-record-sets \
  --hosted-zone-id $HOSTED_ZONE_ID \
  --query "ResourceRecordSets[?(Name==\`$REGISTRY_HOST.\` && Type==\`CNAME\`)].Name" \
  --output text)

ENTRY_A=$(aws route53 list-resource-record-sets \
  --hosted-zone-id $HOSTED_ZONE_ID \
  --query "ResourceRecordSets[?(Name==\`$REGISTRY_HOST.\` && Type==\`A\`)].Name" \
  --output text)

if [ -z $ENTRY_CNAME ] && [ -z $ENTRY_A ]; then
  echo "ERROR: Vanity domain missing: - $REGISTRY_HOST"
  exit
else
  echo "Vanity domain exists: $REGISTRY_HOST"
fi

echo "Creating namespace: $K8S_REGISTRY_NAMESPACE"
kubectl apply -f - <<EOF
apiVersion: v1
kind: Namespace
metadata:
    name: $K8S_REGISTRY_NAMESPACE
    labels:
        name: $K8S_REGISTRY_NAMESPACE
EOF

# Does the cluster issuer exist?

kubectl get clusterissuer $ISSUER 1>/dev/null 2>&1
if [ $? != 0 ]; then
    echo "ERROR: Missing issuer: $ISSUER"
    exit
else
    echo "Issuer exists: $ISSUER"
fi

kubectl apply -f - <<EOF
apiVersion: cert-manager.io/v1alpha2
kind: Certificate
metadata:
  name: docker-registry-certificate
  namespace: $K8S_REGISTRY_NAMESPACE
spec:
  secretName: docker-registry-tls-certificate
  issuerRef:
    name: $ISSUER
    kind: ClusterIssuer
  dnsNames:
  - $REGISTRY_HOST
EOF

# The following command can be used for debugging.
# kubectl describe certificate docker-registry --namespace=$K8S_REGISTRY_NAMESPACE

# This script uses two secrets. One to hold the password for people to login 
# with. And the other for the container to hold to authenticate with.

# This password is used two ways. One is passed into the container encrypted
# using HTPASSWD which can't be recovered as clear text. The other is intended
# to be used by a docker login script.

kubectl get secret docker-registry-admin-password 1>/dev/null 2>&1
if [ $? == 0 ]; then
    echo "Registry password secret exists."
    PASSWORD=$(kubectl get secret --namespace $K8S_REGISTRY_NAMESPACE docker-registry-admin-password -o jsonpath="{.data.password}" | base64 --decode)
else
    PASSWORD=$(uuid)
    # Note that yaml files are not written so that the password is never stored locally.

    kubectl apply -f - <<EOF
apiVersion: v1
kind: Secret
type: Opaque
metadata:
    name: docker-registry-admin-password
    namespace: $K8S_REGISTRY_NAMESPACE
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
    namespace: $K8S_REGISTRY_NAMESPACE
data:
    HTPASSWD: $HTPASSWORD
EOF
fi

# Create a configuration map where the authentication method is defined to be Basic Auth.

kubectl apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: docker-registry
  namespace: $K8S_REGISTRY_NAMESPACE
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

# Define pod.

kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: docker-registry
  namespace: $K8S_REGISTRY_NAMESPACE
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

# Create a service.

kubectl apply -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: docker-registry
  namespace: $K8S_REGISTRY_NAMESPACE
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

# Create an ingress.

kubectl apply -f - <<EOF
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: docker-registry
  namespace: $K8S_REGISTRY_NAMESPACE
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
