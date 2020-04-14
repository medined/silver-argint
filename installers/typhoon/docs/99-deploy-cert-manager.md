# Deploy cert-manager

cert-manager builds on top of Kubernetes, introducing certificate authorities and certificates as first-class resource types in the Kubernetes API. This makes it possible to provide 'certificates as a service' to developers working within your Kubernetes cluster.

This document shows how to use cert-manager in a sandbox namespace.

## Links

* https://cert-manager.io/
* https://cert-manager.io/docs/tutorials/acme/ingress/


### Steps

* Define the email for domain certifications.

```bash
export ACME_REGISTRATION_EMAIL=dmedined@crimsongovernment.com
```

* Install certificate manager.

```bash
helm repo add jetstack https://charts.jetstack.io
helm install cert-manager jetstack/cert-manager --version v0.13.0 --namespace kube-system
```

* Check the pods.

```bash
kubectl get all --namespace kube-system
```

* Create cert-manager namespace.

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

* Create Let's Encrypt Issuer for a development and production environments. The main difference is the ACME server URL.

```
kubectl apply -f - <<EOF
apiVersion: cert-manager.io/v1alpha2
kind: Issuer
metadata:
  name: letsencrypt-development-issuer
  namespace: cert-manager
spec:
  acme:
    server: https://acme-staging-v02.api.letsencrypt.org/directory
    email: $ACME_REGISTRATION_EMAIL
    privateKeySecretRef:
      name: letsencrypt-development-issuer
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
    server: https://acme-v02.api.letsencrypt.org/directory
    email: $ACME_REGISTRATION_EMAIL
    privateKeySecretRef:
      name: letsencrypt-production-issuer
    solvers:
    - http01:
        ingress:
          class: nginx
EOF
```

* Check on the status of the development issuer. But entries should be ready.

```
kubectl get issuer --namespace cert-manager
```
