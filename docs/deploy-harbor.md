# Deploy Harbor

Harbor is the most secure, performant, scalable, and available cloud native repository for Kubernetes.

## Links

* Harbor
 * https://goharbor.io/
 * https://github.com/goharbor/harbor/blob/master/docs/1.10/install-config/harbor-ha-helm.md

### Harbor Goals

* remote registry - proxy to Docker Hub.
* demonstrate vulnerability report.
* create developer member.

## Steps

* Export some variables to parameterize later steps.

```
export HARBOR_HOST=harbor.va-oit.cloud
export ISSUER_REF=letsencrypt-development-issuer
```

* Request a PKI cerificate. Notce that the namespace is specified in the manifest file.

```
cat <<EOF > yaml/harbor-certificate.yaml
apiVersion: cert-manager.io/v1alpha2
kind: Certificate
metadata:
  name: harbor
  namespace: sandbox
spec:
  secretName: harbor-tls-certificate
  issuerRef:
    name: $ISSUER_REF
  dnsNames:
  - $HARBOR_HOST
EOF
kubectl apply -f yaml/harbor-certificate.yaml
```

* Check the certificate status.

```
kubectl describe certificate harbor
```

* Add the harbor repository to helm.

```
helm repo add harbor https://helm.goharbor.io
```

* Download the helm chart. This creates a harbor directory. Read the readme online at https://hub.helm.sh/charts/harbor/harbor.

```
helm fetch harbor/harbor --untar
```

* Edit `harbor/values.yaml`.
    * Change export.type to be `ClusterIP`.