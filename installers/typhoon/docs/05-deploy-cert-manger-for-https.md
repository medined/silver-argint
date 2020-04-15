# Deploy Service With HTTPS

* Deploy text-reponder with HTTP.

```
kubectl delete namespace text-responder
./scripts/deploy-namespace-text-responder.sh
```

* Create a namespace for `cert-manager`.

```bash
kubectl apply -f - <<EOF
apiVersion: v1
kind: Namespace
metadata:
    name: cert-manager
    labels:
        name: cert-manager
EOF
```

* Install the custom resource definitions.

```bash
kubectl apply --validate=false -f https://github.com/jetstack/cert-manager/releases/download/v0.14.1/cert-manager.crds.yaml
```

* Install certificate manager. Check the chart versions at https://hub.helm.sh/charts/jetstack/cert-manager to find the latest version number.

```
helm repo add jetstack https://charts.jetstack.io
helm install cert-manager jetstack/cert-manager --version v0.14.2 --namespace cert-manager
```

* Create an issuer to test the webhook works okay.


```bash
kubectl apply -f - <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: cert-manager-test
---
apiVersion: cert-manager.io/v1alpha2
kind: Issuer
metadata:
  name: test-selfsigned
  namespace: cert-manager-test
spec:
  selfSigned: {}
---
apiVersion: cert-manager.io/v1alpha2
kind: Certificate
metadata:
  name: selfsigned-cert
  namespace: cert-manager-test
spec:
  dnsNames:
    - example.com
  secretName: selfsigned-cert-tls
  issuerRef:
    name: test-selfsigned
EOF
```

* Check the new certificate. You should see "Certificate issued successfully".

```bash
kubectl describe certificate -n cert-manager-test
```

* Cleanup the test resources.

```bash
kubectl delete namespace cert-manager-test
```

* Create Let's Encrypt ClusterIssuer for staging and production environments. The main difference is the ACME server URL. I use the term `staging` because that is what Let's Encrypt uses.

>Change the email address.

```bash
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
```

* Check on the status of the development issuer. The entries should be ready.

```
kubectl get clusterissuer
```

* Add annotation to text-responder ingress. This uses the staging Let's Encrypt to avoid rate limited while testing.

```bash
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1beta1
kind: Ingress
metadata:
  name: text-responder-ingress
  namespace: text-responder
  annotations:
    kubernetes.io/ingress.class: nginx
    cert-manager.io/cluster-issuer: letsencrypt-staging
spec:
  tls:
  - hosts:
    - text-responder.david.va-oit.cloud
    secretName: text-responder-tls
  rules:
  - host: text-responder.david.va-oit.cloud
    http:
      paths:
      - backend:
          serviceName: text-responder
          servicePort: 80
        path: "/"
EOF
```

* Review the certificate that cert-manager has created. 

```bash
kubectl -n text-responder describe certificate text-responder-tls
```

* Review the secret that is being created by cert-manager.

```bash
kubectl -n text-responder describe secret text-responder-tls
```


* Add annotation to text-responder ingress.

```bash
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1beta1
kind: Ingress
metadata:
  name: text-responder-ingress
  namespace: text-responder
  annotations:
    kubernetes.io/ingress.class: nginx
    cert-manager.io/cluster-issuer: letsencrypt-production
spec:
  tls:
  - hosts:
    - text-responder.david.va-oit.cloud
    secretName: text-responder-tls
  rules:
  - host: text-responder.david.va-oit.cloud
    http:
      paths:
      - backend:
          serviceName: text-responder
          servicePort: 80
        path: "/"
EOF
```

* Delete secret to get new certificate.

```
k -n text-responder delete secret text-responder-tls
```

* At this point, an HTTPS request should work.

```bash
curl https://text-responder.david.va-oit.cloud/
```
