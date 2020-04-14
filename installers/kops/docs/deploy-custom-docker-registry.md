# Deploy Public Docker Registry

## Links

* https://www.nearform.com/blog/how-to-run-a-public-docker-registry-in-kubernetes/

## Goal

To allow k8s to use images from a private docker registry hosted inside the k8s cluster.

## Prequisites

* A namespace with cert-manager deployed.

## Scripted Process

```
CONFIG_FILE="$HOME/va-oit.cloud.env"
NAMESPACE=sandbox
./custom-docker-registry-install.sh -f $CONFIG_FILE $NAMESPACE
```

## Manual Process

After deploying the docker registry, this process shows how to pull an image from the registry for a pod.

* Does the namespace exist?

```
export NAMESPACE=sandbox
kubectl get namespace $NAMESPACE
```

* Create a vanity URL using the steps [here](create-vanity-url.md). Use `registry` as the service name.

```
export DOMAIN_NAME="va-oit-green.cloud"
export REGISTRY_HOST=registry.$DOMAIN_NAME
```

* Does the certificate issuer exist?

```
export ISSUER_REF=letsencrypt-production-issuer
kubectl get issuer $ISSUER_REF
```

* Request a PKI cerificate. Notice that the namespace is specified in the manifest file.

```
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
```

* Switch to the namespace.

```
kubectl config set-context --current --namespace=$NAMESPACE
```

* Check the certificate status.

```
kubectl describe certificate docker-registry
```

* Save an admin password for the registry.

```
export PASSWORD=$(uuid)

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
```

* Encrypt the password using `htpasswd` which the docker registry understands.

```
docker pull registry:2
HTPASSWORD=$(docker run --entrypoint htpasswd --rm registry:2 -Bbn admin $PASSWORD | base64 --wrap 92)

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
```

* Create a configuration map where the authentication method is defined to be Basic Auth.

```
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
```

* Define a pod.

```
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
```

* Create a service.

```
cat <<EOF > yaml/registry-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: docker-registry
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
```

* Create an ingress.

```
cat <<EOF > yaml/registry-ingress.yaml
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: docker-registry
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
```

### Test the Registry

* Use curl to list the catalog.

```
curl -u admin:$PASSWORD https://$REGISTRY_HOST/v2/_catalog
{"repositories":[]}
```

* Push an image to the registry.

```
docker login https://$REGISTRY_HOST -u admin -p $PASSWORD
docker pull busybox:latest
docker tag busybox:latest $REGISTRY_HOST/busybox:latest
docker push $REGISTRY_HOST/busybox:latest
```

* View the registry catalog again.

```
curl -u admin:$PASSWORD https://$REGISTRY_HOST/v2/_catalog
{"repositories":["busybox"]}
```

* The script `docker-registry-login.sh` can be used to automatically log into the registry.

### Create Secret To Hold Registry Credentials 

This secret hold the credentials needed for k8s to pull images from a private registry.

```
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
```

### Demonstrate Pulling Image From Custom Registry

In order to demonstrate pullin an image from the custom registry, you'll:

* create an image with a known file.
* push it.
* create a pod.
* use exec to list the known file.

First, create an image.

```
mkdir /tmp/custom-registry-test
pushd /tmp/custom-registry-test

REGISTRY_HOST=registry.va-oit-green.cloud

cat <<EOF > Dockerfile
FROM nginx
RUN echo "AAA" > /custom-registry.test.file
EOF

./custom-docker-registry-login.sh
docker build -t nginx-test:latest .
docker tag nginx-test:latest $REGISTRY_HOST/nginx-test:latest
docker push $REGISTRY_HOST/nginx-test:latest
popd
```

Now create a pod to use that image.

```
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: registry-secret-demo
spec:
  volumes:
  - name: shared-data
    emptyDir: {}
  containers:
  - name: nginx
    image: $REGISTRY_HOST/nginx-test:latest
    imagePullPolicy: Always
    volumeMounts:
    - name: shared-data
      mountPath: /usr/share/nginx/html
  hostNetwork: true
  dnsPolicy: Default
  imagePullSecrets:
  - name: docker-registry-credentials
EOF
```

Lastly, list the root directory to see the `/custom-registry.test.file` file.

```
kubectl exec -it registry-secret-demo -- ls -l /
```

After testing, you can delete the pod.

```
kubectl delete pod registry-secret-demo
```