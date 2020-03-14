#!/bin/bash

# This script installs a public docker registry into k8s.
#  https://www.nearform.com/blog/how-to-run-a-public-docker-registry-in-kubernetes/
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
ISSUER_REF=letsencrypt-production-issuer

./cert-manager-install.sh -f $CONFIG_FILE $NAMESPACE
./create-vanity-url.sh $SERVICE_NAME $DOMAIN_NAME

REGISTRY_HOST="$SERVICE_NAME.$DOMAIN_NAME"
echo "REGISTRY_HOST: $REGISTRY_HOST"

cat <<EOF > yaml/registry-certificate.yaml
apiVersion: cert-manager.io/v1alpha2
kind: Certificate
metadata:
  name: docker-registry
  namespace: $NAMESPACE
spec:
  secretName: docker-registry-tls-certificate
  issuerRef:
    name: $ISSUER_REF
  dnsNames:
  - $REGISTRY_HOST
EOF
kubectl apply -f yaml/registry-certificate.yaml

# The following command can be used for debugging.
# kubectl describe certificate docker-registry --namespace=$NAMESPACE

PASSWORD_FILENAME="password-docker-registry-$NAMESPACE.txt"
LOCAL_PASSWORD_PATH="/tmp/$PASSWORD_FILENAME"

DOMAIN_NAME_SAFE=$(echo $DOMAIN_NAME | tr [:upper:] [:lower:] | tr '.' '-')
DOMAIN_NAME_S3="s3://$DOMAIN_NAME_SAFE-$(echo -n $DOMAIN_NAME | sha256sum | cut -b-10)"
S3_PASSWORD_KEY="$DOMAIN_NAME_S3/$PASSWORD_FILENAME"

if [ ! -f $LOCAL_PASSWORD_PATH ]; then
    # Store the password for future use.
    PASSWORD=$(uuid)
    echo $PASSWORD > $LOCAL_PASSWORD_PATH
    chmod 600 $LOCAL_PASSWORD_PATH
else
    PASSWORD=$(cat $LOCAL_PASSWORD_PATH)
fi

aws s3 cp $LOCAL_PASSWORD_PATH $S3_PASSWORD_KEY

docker pull registry:2
HTPASSWORD=$(docker run --entrypoint htpasswd --rm registry:2 -Bbn admin $PASSWORD | base64 --wrap 92)
echo "ADMIN Password: $PASSWORD"
echo "HTPASSWORD: $HTPASSWORD"

# Store the admin password into k8s.

cat <<EOF > yaml/registry-admin-password-secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: docker-registry
  namespace: $NAMESPACE
type: Opaque
data:
  HTPASSWD: $HTPASSWORD
EOF
kubectl apply -f yaml/registry-admin-password-secret.yaml

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
        secretName: docker-registry
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
    certmanager.k8s.io/issuer: $ISSUER_REF
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

echo "Waiting 30 seconds for SSL certificate"
sleep 30

# Test the registry.

echo "----------------"
echo "Registry Catalog"
curl -u admin:$PASSWORD https://$REGISTRY_HOST/v2/_catalog

echo "----------------"
echo "Push an image to the registry"

docker login https://$REGISTRY_HOST -u admin -p $PASSWORD
docker pull busybox:latest
docker tag busybox:latest $REGISTRY_HOST/busybox:latest
docker push $REGISTRY_HOST/busybox:latest

echo "----------------"
echo "Registry Catalog. Should be an image now."
curl -u admin:$PASSWORD https://$REGISTRY_HOST/v2/_catalog

echo "----------------"
echo "Use ./docker-registry-login.sh to log into the registry."
