# Deploy cert-manager

cert-manager builds on top of Kubernetes, introducing certificate authorities and certificates as first-class resource types in the Kubernetes API. This makes it possible to provide 'certificates as a service' to developers working within your Kubernetes cluster.

This document shows how to use cert-manager in a sandbox namespace.

## Links

* https://cert-manager.io/
* https://cert-manager.io/docs/tutorials/acme/ingress/

## Prequisites

* [Create sandbox Namespace](create-sandbox-namespace.md)

While the instructions show how to create a namespace named `sandbox`, please create uniquely-named namespace so that your work does not interfere anyone else.

## Steps

* Install certificate manager.

```
helm repo add jetstack https://charts.jetstack.io
helm install cert-manager jetstack/cert-manager --version v0.13.0 --namespace kube-system
```

### Deploy Echo Application

The echo service being deployed here just returns "silverargint" as a text response. Its simplicity makes it a great for this kind of preliminary exploration.

* Create a dummy echo server which is a small web server that returns a text message. This is called an application because it has both a service and a deployment.

```
# Update this assignment to use your uniquely-named namespace.
NAMESPACE=sandbox

cat <<EOF > yaml/echo-application.yaml
apiVersion: v1
kind: Service
metadata:
  name: echo
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
  name: echo
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
      - name: echo
        image: hashicorp/http-echo
        args:
        - "-text=silverargint"
        ports:
        - containerPort: 5678
EOF
kubectl apply -f yaml/echo-application.yaml
```

* Check the service is running. You should see the `echo` service in the list.

```
kubectl get service --namespace $NAMESPACE
```

* Get the load balancer hostname assigned to your nginx-ingress-controller service.

```
K8S_HOSTNAME=$(kubectl get service dmm-nginx-ingress-controller --namespace $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
echo $K8S_HOSTNAME
```

* Create a vanity URL for the echo service using the steps [here](create-vanity-url.md). Use `echo` as the service name.

* Route traffic directed at the `echo` subdomain within the cluster.

```
cat <<EOF > yaml/echo-ingress.yaml
apiVersion: networking.k8s.io/v1beta1
kind: Ingress
metadata:
  name: echo-ingress
  namespace: $NAMESPACE
spec:
  rules:
  - host: echo.$NAME
    http:
      paths:
      - backend:
          serviceName: echo
          servicePort: 80
EOF
kubectl apply -f yaml/echo-ingress.yaml
```

* Call the echo service. It should return `silverargint`.

```
curl echo.$NAME
```

### Integrate With Let's Encrypt

* Create Let's Encrypt Issuer for a development and production environments. The main difference is the ACME server URL.

```
cat <<EOF > yaml/kuard-issuer.yaml
apiVersion: cert-manager.io/v1alpha2
kind: Issuer
metadata:
  name: letsencrypt-development-issuer
  namespace: $NAMESPACE
spec:
  acme:
    # The ACME server URL
    server: https://acme-staging-v02.api.letsencrypt.org/directory
    # Email address used for ACME registration
    email: dmedined@crimsongovernment.com
    # Name of a secret used to store the ACME account private key
    privateKeySecretRef:
      name: letsencrypt-development-issuer
    # Enable the HTTP-01 challenge provider
    solvers:
    - http01:
        ingress:
          class: nginx
---
apiVersion: cert-manager.io/v1alpha2
kind: Issuer
metadata:
  name: letsencrypt-production-issuer
  namespace: $NAMESPACE
spec:
  acme:
    # The ACME server URL
    server: https://acme-v02.api.letsencrypt.org/directory
    # Email address used for ACME registration
    email: dmedined@crimsongovernment.com
    # Name of a secret used to store the ACME account private key
    privateKeySecretRef:
      name: letsencrypt-production-issuer
    # Enable the HTTP-01 challenge provider
    solvers:
    - http01:
        ingress:
          class: nginx
EOF
kubectl create -f yaml/kuard-issuer.yaml
```

* Check on the status of the development issuer. But entries should be ready.

```
kubectl get issuer --namespace $NAMESPACE
```

### Deploy Kuard Application

Kuard is a demonstration application from the "Kubernetes Up and Running" book. It is another example how to deploy an application.

* Create a vanity URL using the steps [here](create-vanity-url.md). Use `kuard` as the service name.

* Deploy the kuard application.

```
cat <<EOF > yaml/kuard-application.yaml
apiVersion: v1
kind: Service
metadata:
  name: kuard
  namespace: $NAMESPACE
spec:
  ports:
  - port: 80
    targetPort: 8080
    protocol: TCP
  selector:
    app: kuard
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: kuard
  namespace: $NAMESPACE
spec:
  selector:
    matchLabels:
      app: kuard
  replicas: 1
  template:
    metadata:
      labels:
        app: kuard
    spec:
      containers:
      - image: gcr.io/kuar-demo/kuard-amd64:1
        imagePullPolicy: Always
        name: kuard
        ports:
        - containerPort: 8080
---
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: kuard
  namespace: $NAMESPACE
  annotations:
    kubernetes.io/ingress.class: nginx
    cert-manager.io/issuer: letsencrypt-development-issuer
spec:
  tls:
  - hosts:
    - kuard.$NAME
    secretName: quickstart-example-tls
  rules:
  - host: kuard.$NAME
    http:
      paths:
      - path: /
        backend:
          serviceName: kuard
          servicePort: 80
EOF
kubectl apply -f yaml/kuard-application.yaml
```

* Verify the ingress has been created. Repeat until the Address field is valid.

```
kubectl get ingress --namespace $NAMESPACE
```

* Look at the new certificate.

```
kubectl get certificate --namespace $NAMESPACE
```

* Describe the certificate. Hopefully, the last message says "Certificate issued successfully".

```
kubectl describe certificate quickstart-example-tls --namespace $NAMESPACE
```

* Check that a secret has been created with the details of the certificate.

```
kubectl describe secret quickstart-example-tls --namespace $NAMESPACE
```

* You should be able to visit the running `kuard` application now.

```
firefox https://kuard.$NAME
```

* Now update the ingress to use `production` Let's Encrypt.

```
cat <<EOF > yaml/kuard-ingress.yaml
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: kuard
  namespace: $NAMESPACE
  annotations:
    kubernetes.io/ingress.class: nginx
    cert-manager.io/issuer: letsencrypt-production-issuer
spec:
  tls:
  - hosts:
    - kuard.$NAME
    secretName: quickstart-example-tls
  rules:
  - host: kuard.$NAME
    http:
      paths:
      - path: /
        backend:
          serviceName: kuard
          servicePort: 80
EOF
kubectl apply -f yaml/kuard-ingress.yaml
```

* Delete the existing secret. This will trigger a new certificate request.

```
kubectl delete secret quickstart-example-tls --namespace sandbox
```

* Describe the certificate. Hopefully, the last message says "Certificate issued successfully". If not wait a few minutes.

```
kubectl describe certificate quickstart-example-tls --namespace sandbox
```
