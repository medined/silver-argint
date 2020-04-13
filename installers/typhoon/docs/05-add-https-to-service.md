# Deploy Service With HTTPS

* Create a namespace.

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

* Install certificate manager.

```
helm repo add jetstack https://charts.jetstack.io
helm install cert-manager jetstack/cert-manager --version v0.14.1 --namespace cert-manager
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

* Create Let's Encrypt Issuer for a development and production environments. The main difference is the ACME server URL.

```
kubectl apply -f - <<EOF
apiVersion: cert-manager.io/v1alpha2
kind: Issuer
metadata:
  name: letsencrypt-staging
  namespace: text-responder
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
EOF
```

* Check on the status of the development issuer. The entries should be ready.

```
kubectl get issuer --namespace $NAMESPACE
```

* Add annotation to text-responder ingress.

```bash
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1beta1
kind: Ingress
metadata:
  name: text-responder-ingress
  namespace: $NAMESPACE
  annotations:
    kubernetes.io/ingress.class: public
    cert-manager.io/acme-challenge-type: http01
    cert-manager.io/issuer: letsencrypt-staging
spec:
  tls:
  - hosts:
    - $TEXT_RESPONDER_HOST
    secretName: text-responder-tls
  rules:
  - host: $TEXT_RESPONDER_HOST
    http:
      paths:
      - backend:
          serviceName: text-responder
          servicePort: 80
EOF
```
