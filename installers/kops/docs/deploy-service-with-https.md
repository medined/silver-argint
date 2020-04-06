# Deploy Service With HTTPS

## Prerequisites

* Set the namespace.

```bash
NAMESPACE=sandbox
```

* Validate the namespace.

```bash
kubectl get namespace $NAMESPACE
```

* Make sure the certificate issuer has been installed. You should see both `letsencrypt-development-issuer` and `letsencrypt-production-issuer`

```bash
kubectl get issuer --namespace $NAMESPACE
```

## Deploy text-responder Application

The service being deployed here just returns "silverargint" as a text response. Its simplicity makes it a great for this kind of preliminary exploration.

* Create a simple server which is a small web server that returns a text message. This is called an application because it has both a service and a deployment.

```bash
cat <<EOF > yaml/echo-application.yaml
apiVersion: v1
kind: Service
metadata:
  name: text-responder
  namespace: $NAMESPACE
spec:
  ports:
  - port: 80
    targetPort: 5678
  selector:
    app: echo
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: text-responder
  namespace: $NAMESPACE
spec:
  selector:
    matchLabels:
      app: echo
  replicas: 2
  template:
    metadata:
      labels:
        app: echo
    spec:
      containers:
      - name: text-responder
        image: hashicorp/http-echo
        args:
        - "-text=silverargint"
        ports:
        - containerPort: 5678
EOF
kubectl apply -f yaml/echo-application.yaml
```

* Check the service is running. You should see the `text-responder` service in the list.

```bash
kubectl get service --namespace $NAMESPACE
```

* Get the load balancer hostname assigned to your nginx-ingress-controller service.

```bash
K8S_HOSTNAME=$(kubectl get service $NAMESPACE-nginx-ingress-controller --namespace $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
echo $K8S_HOSTNAME
```

* Create a vanity URL for the service using the steps [here](create-vanity-url.md). Use `text-responder` as the service name.

```bash
./create-vanity-url.sh -f $CONFIG_FILE $NAMESPACE text-responder
```

* Curl should get the default backend response.

```bash
curl http://text-responder.$DOMAIN_NAME;echo
default backend - 404
```

* Route traffic directed at the `text-responder` subdomain within the cluster.

```bash
cat <<EOF > yaml/text-responder-ingress.yaml
apiVersion: networking.k8s.io/v1beta1
kind: Ingress
metadata:
  name: text-responder-ingress
  namespace: $NAMESPACE
spec:
  rules:
  - host: text-responder.$DOMAIN_NAME
    http:
      paths:
      - backend:
          serviceName: text-responder
          servicePort: 80
EOF
kubectl apply -f yaml/text-responder-ingress.yaml
```

* Call the service. It should return `silverargint`.

```
curl http://text-responder.$DOMAIN_NAME
```

### Integrate With Let's Encrypt

```bash
cat <<EOF > yaml/text-responder-ingress.yaml
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
    - text-responder.$DOMAIN_NAME
    secretName: text-responder-tls
  rules:
  - host: text-responder.$DOMAIN_NAME
    http:
      paths:
      - backend:
          serviceName: text-responder
          servicePort: 80
EOF
kubectl apply -f yaml/text-responder-ingress.yaml
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
kubectl describe certificate quickstart-example-tls --namespace $NAMESPACE
```

* Check that a secret has been created with the details of the certificate.

```bash
kubectl describe secret quickstart-example-tls --namespace $NAMESPACE
```

* You should be able to visit the running application now. This is still an insecure https request because it used the development issuer.

```bash
curl -k https://text-responder.$DOMAIN_NAME
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
    - text-responder.$DOMAIN_NAME
    secretName: text-responder-tls
  rules:
  - host: text-responder.$DOMAIN_NAME
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
