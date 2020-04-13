# Deploy Service With HTTPS

## Process

* Deploy text-responder using 04-deploy-service-with-http.md

* Apply the kube-lego manifests. These were pulled from the examples/nginx/lego directory of the https://github.com/jetstack/kube-lego.git project.

```bash
kubectl apply -R -f kube-lego
```

* Addd a annotation to the text-responder ingress to activate kube-lego.

```bash
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1beta1
kind: Ingress
metadata:
  name: text-responder-ingress
  namespace: $NAMESPACE
  annotations:
    kubernetes.io/ingress.class: public
    kubernetes.io/tls-acme: "true"
spec:
  tls:
  - secretName: text-responder-tls
    hosts: 
    - $TEXT_RESPONDER_HOST
  rules:
  - host: $TEXT_RESPONDER_HOST
    http:
      paths:
      - backend:
          serviceName: text-responder
          servicePort: 80
EOF
```

* Look at resources in kube-lego namespace.

```bash
kubectl -n kube-lego get all
```

* Change the ingress by adding a dummy annotation so that nginx gets restarted.

```bash
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1beta1
kind: Ingress
metadata:
  name: text-responder-ingress
  namespace: $NAMESPACE
  annotations:
    kubernetes.io/ingress.class: public
    kubernetes.io/tls-acme: "true"
    dummy: v1
spec:
  tls:
  - secretName: text-responder-tls
    hosts: 
    - $TEXT_RESPONDER_HOST
  rules:
  - host: $TEXT_RESPONDER_HOST
    http:
      paths:
      - backend:
          serviceName: text-responder
          servicePort: 80
EOF
```


=========================================================
=========================================================
=========================================================
=========================================================
=========================================================
=========================================================

### Integrate With Let's Encrypt

* Make sure the certificate issuer has been installed. You should see both `letsencrypt-development-issuer` and `letsencrypt-production-issuer`

```bash
kubectl get issuer --namespace cert-manager
```

* Create ingress.

```bash
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1beta1
kind: Ingress
metadata:
  name: text-responder-ingress
  namespace: $NAMESPACE
  annotations:
    kubernetes.io/ingress.class: nginx
    cert-manager.io/issuer: letsencrypt-development-issuer
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

* Verify the ingress has been created. Repeat until the Address field is valid.

```bash
kubectl get ingress --namespace $NAMESPACE
```

* Look at the new certificate.

```bash
kubectl get certificate --namespace $NAMESPACE
```

* Describe the certificate. Hopefully, the last message says "Certificate issued successfully".

```bash
kubectl describe certificate text-responder-tls --namespace $NAMESPACE
```

* Check that a secret has been created with the details of the certificate.

```bash
kubectl describe secret text-responder-tls --namespace $NAMESPACE
```

* You should be able to visit the running application now. This is still an insecure https request because it used the development issuer.

```bash
curl -k https://$TEXT_RESPONDER_HOST
```

* Now update the ingress to use `production` Let's Encrypt.

```bash
cat <<EOF > yaml/text-responder-ingress.yaml
apiVersion: networking.k8s.io/v1beta1
kind: Ingress
metadata:
  name: text-responder-ingress
  namespace: $NAMESPACE
  annotations:
    kubernetes.io/ingress.class: nginx
    cert-manager.io/issuer: letsencrypt-production-issuer
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
kubectl apply -f yaml/text-responder-ingress.yaml
```

* Delete the existing secret. This will trigger a new certificate request.

```bash
kubectl delete secret text-responder-tls --namespace $NAMESPACE
```

* Describe the certificate. Hopefully, the last message says "Certificate issued successfully". If not wait a few minutes.

```bash
kubectl describe certificate text-responder-tls --namespace $NAMESPACE
```
