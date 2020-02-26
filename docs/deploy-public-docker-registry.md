# Deploy Public Docker Registry

## Links

* https://www.nearform.com/blog/how-to-run-a-public-docker-registry-in-kubernetes/

## Prequisites

* [Deploy Certificate Manager](deploy-cert-manager.md)
* a sandbox namespace.

## Goal

```
curl -u user:pass https://registry.va-oit.cloud/v2/catalog
```

## Steps

  * Define the DNS action which is inserting or updating the echo hostname.

```
cat <<EOF > json/dns-action.json
{
  "Changes": [
    {
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "registry.$NAME",
        "Type": "CNAME",
        "TTL": 300,
        "ResourceRecords": [
          {
            "Value": "$K8S_HOSTNAME"
          }
        ]
      }
    }
  ]
}
EOF

export HOSTED_ZONE_NAME=va-oit.cloud
export HOSTED_ZONE_ID=$(aws route53 list-hosted-zones-by-name --query "HostedZones[?Name==\`$NAME.\`].Id" --output text)

echo "NAME:           $NAME"
echo "HOSTED_ZONE_ID: $HOSTED_ZONE_ID"
echo "K8S_HOSTNAME:   $K8S_HOSTNAME"

aws route53 change-resource-record-sets \
  --hosted-zone-id $HOSTED_ZONE_ID \
  --change-batch file://json/dns-action.json
```

* Check the DNS record was created.

```
aws route53 list-resource-record-sets \
  --hosted-zone-id $HOSTED_ZONE_ID \
  --query="ResourceRecordSets[?Name==\`registry.$NAME.\`]"
```

* Export some variables to parameterize later steps.

```
export REGISTRY_HOST=registry.$NAME
export ISSUER_REF=letsencrypt-production-issuer
```

* Request a PKI cerificate. Notce that the namespace is specified in the manifest file.

```
cat <<EOF > yaml/registry-certificate.yaml
apiVersion: cert-manager.io/v1alpha2
kind: Certificate
metadata:
  name: docker-registry
  namespace: sandbox
spec:
  secretName: docker-registry-tls-certificate
  issuerRef:
    name: $ISSUER_REF
  dnsNames:
  - $REGISTRY_HOST
EOF
kubectl apply -f yaml/registry-certificate.yaml
```

* Switch to the sandbox namespace.

```
kubectl config set-context --current --namespace=sandbox
```

* Check the certificate status.

```
kubectl describe certificate docker-registry
```

* Create a secret password for the `admin` user. The image is pulled before use so that we can capture stdout cleanly.

```
PASSWORD=$(uuid)

# Store the password for future use. This file is ignored by git.
echo $PASSWORD > password-docker-registry.txt
chmod 600 password-docker-registry.txt

docker pull registry:2
HTPASSWORD=$(docker run --entrypoint htpasswd --rm registry:2 -Bbn admin $PASSWORD | base64 --wrap 92)
echo "ADMIN Password: $PASSWORD"
echo "HTPASSWORD: $HTPASSWORD"

cat <<EOF > yaml/registry-admin-password-secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: docker-registry
  namespace: sandbox
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
  namespace: sandbox
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
  namespace: sandbox
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

* Test the registry.

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
