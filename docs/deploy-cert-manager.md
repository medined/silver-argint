# Deploy cert-manager

cert-manager builds on top of Kubernetes, introducing certificate authorities and certificates as first-class resource types in the Kubernetes API. This makes it possible to provide 'certificates as a service' to developers working within your Kubernetes cluster.

This document shows how to use cert-manager in a sandbox namespace.

## Links

* https://cert-manager.io/
* https://cert-manager.io/docs/tutorials/acme/ingress/

## Steps

* Install certificate manager.

```
helm repo add jetstack https://charts.jetstack.io
helm install cert-manager jetstack/cert-manager --version v0.13.0 --namespace kube-system
```

* Create sandbox namespace.

```
cat <<EOF > yaml/namespace-sandbox.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: sandbox
  labels:
    name: sandbox
EOF
kubectl create -f yaml/namespace-sandbox.yaml
```

* Install ingress controller. Note that `dmm` is used as a prefix.

```
helm install dmm stable/nginx-ingress --namespace sandbox
```

* Get the load balancer hostname assigned to your nginx-ingress-controller service.

```
K8S_HOSTNAME=$(kubectl get service dmm-nginx-ingress-controller --namespace sandbox -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
echo $K8S_HOSTNAME
```

### Deploy Echo Application

The echo serivce being deployed here just returns "silverargint" as a text response. Its simplicity makes it a great for this kind of preliminary exploration.

* Create a dummy echo server which is a small web server that returns a text message. This is called an application because it has both a service and a deployment.

```
cat <<EOF > yaml/echo-application.yaml
apiVersion: v1
kind: Service
metadata:
  name: echo
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
kubectl apply -f yaml/echo-application.yaml --namespace sandbox
```

* Check the service is running. You should see the `echo` service in the list.

```
kubectl get service --namespace sandbox
```

* Create a vanity URL for the echo service. Using Route53, create a CNAME record pointing to the K8S_HOSTNAME. For example, echo.va-oit.cloud. Wait a few minutes for the DNS change to propagate. When you get a valid response to `dig NS echo.va-oit.cloud` you can move on.

* Route traffic directed at the `echo` subdomain within the cluster.

```
cat <<EOF > yaml/echo-ingress.yaml
apiVersion: networking.k8s.io/v1beta1
kind: Ingress
metadata:
  name: echo-ingress
spec:
  rules:
  - host: echo.va-oit.cloud
    http:
      paths:
      - backend:
          serviceName: echo
          servicePort: 80
EOF
kubectl apply -f yaml/echo-ingress.yaml --namespace sandbox
```

* Call the echo service. It should return `silverargint`.

```
curl echo.va-oit.cloud
```

### Integrate With Let's Encrypt

* Create Let's Encrypt Issuer for a development environment.

```
cat <<EOF > yaml/kuard-issuer-developmemt.yaml
apiVersion: cert-manager.io/v1alpha2
kind: Issuer
metadata:
  name: letsencrypt-development
spec:
  acme:
    # The ACME server URL
    server: https://acme-staging-v02.api.letsencrypt.org/directory
    # Email address used for ACME registration
    email: dmedined@crimsongovernment.com
    # Name of a secret used to store the ACME account private key
    privateKeySecretRef:
      name: letsencrypt-development
    # Enable the HTTP-01 challenge provider
    solvers:
    - http01:
        ingress:
          class: nginx
EOF
kubectl create -f yaml/kuard-issuer-developmemt.yaml --namespace sandbox
```

* Create a Let's Encrypt Issuer for a production environment.

```
cat <<EOF > yaml/kuard-issuer-production.yaml
apiVersion: cert-manager.io/v1alpha2
kind: Issuer
metadata:
  name: letsencrypt-production
spec:
  acme:
    # The ACME server URL
    server: https://acme-v02.api.letsencrypt.org/directory
    # Email address used for ACME registration
    email: dmedined@crimsongovernment.com
    # Name of a secret used to store the ACME account private key
    privateKeySecretRef:
      name: letsencrypt-production
    # Enable the HTTP-01 challenge provider
    solvers:
    - http01:
        ingress:
          class: nginx
EOF
kubectl create -f yaml/kuard-issuer-production.yaml --namespace sandbox
```

* Check on the status of the development issuer. But entries should be ready.

```
kubectl get issuer --namespace sandbox
```

### Deploy Kuard Application

Kuard is a demonstration application from the "Kubernetes Up and Running" book. It is another example how to deploy and application.

* Create a vanity URL for the kuard service. Using Route53, create a CNAME record pointing to the K8S_HOSTNAME. For example, kuard.va-oit.cloud. Wait a few minutes for the DNS change to propagate. When you get a valid response to `dig NS kuard.va-oit.cloud` you can move on.

* Deploy an example service.

```
cat <<EOF > yaml/kuard-application.yaml
apiVersion: v1
kind: Service
metadata:
  name: kuard
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
  annotations:
    kubernetes.io/ingress.class: nginx
    cert-manager.io/issuer: letsencrypt-development
spec:
  tls:
  - hosts:
    - kuard.va-oit.cloud
    secretName: quickstart-example-tls
  rules:
  - host: kuard.va-oit.cloud
    http:
      paths:
      - path: /
        backend:
          serviceName: kuard
          servicePort: 80
EOF
kubectl apply -f yaml/kuard-application.yaml --namespace sandbox
```

* Verify the ingress has been created. Repeat until the Address field is valid.

```
kubectl get ingress --namespace sandbox
```

* Look at the new certificate.

```
kubectl get certificate --namespace sandbox
```

* Describe the certificate. Hopefully, the last message says "Certificate issued successfully".

```
kubectl describe certificate quickstart-example-tls --namespace sandbox
```

* Check that a secret has been created with the details of the certificate.

```
kubectl describe secret quickstart-example-tls --namespace sandbox
```

* You should be able to visit the running `kuard` application now.

```
https://kuard.va-oit.cloud
```

* Now update the ingress to use `production` Let's Encrypt.

```
cat <<EOF > yaml/kuard-ingress.yaml
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: kuard
  annotations:
    kubernetes.io/ingress.class: nginx
    cert-manager.io/issuer: letsencrypt-production
spec:
  tls:
  - hosts:
    - kuard.va-oit.cloud
    secretName: quickstart-example-tls
  rules:
  - host: kuard.va-oit.cloud
    http:
      paths:
      - path: /
        backend:
          serviceName: kuard
          servicePort: 80
EOF
kubectl apply -f yaml/kuard-ingress.yaml --namespace sandbox
```

* Delete the existing secret. This will trigger a new certificate request.

```
kubectl delete secret quickstart-example-tls --namespace sandbox
```

* Describe the certificate. Hopefully, the last message says "Certificate issued successfully". If not wait a few minutes.

```
kubectl describe certificate quickstart-example-tls --namespace sandbox
```

## Delete sandbox namespace

```
kubectl delete namespace sandbox
kubectl delete clusterrole dmm-nginx-ingress
kubectl delete ClusterRoleBinding dmm-nginx-ingress
```
