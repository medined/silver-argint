# Deploy cert-manager

cert-manager builds on top of Kubernetes, introducing certificate authorities and certificates as first-class resource types in the Kubernetes API. This makes it possible to provide 'certificates as a service' to developers working within your Kubernetes cluster.

This document shows how to use cert-manager in a sandbox namespace.

## Links

* https://cert-manager.io/
* https://cert-manager.io/docs/tutorials/acme/ingress/

## Manual Process

### Prequisites

* [Create sandbox Namespace](create-sandbox-namespace.md)

While the instructions show how to create a namespace named `sandbox`, please create uniquely-named namespace so that your work does not interfere anyone else.

### Steps

* Install certificate manager.

```bash
helm repo add jetstack https://charts.jetstack.io
helm install cert-manager jetstack/cert-manager --version v0.13.0 --namespace kube-system
```

### Deploy Echo Application

The echo service being deployed here just returns "silverargint" as a text response. Its simplicity makes it a great for this kind of preliminary exploration.

* Create a dummy echo server which is a small web server that returns a text message. This is called an application because it has both a service and a deployment.

```bash
NAMESPACE=ingress
kubectl config set-context --current --namespace=$NAMESPACE

kubectl apply -f - <<EOF
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
```

* Check the service is running. You should see the `echo` service in the list.

```bash
kubectl get service --namespace $NAMESPACE
```

* Get the load balancer hostname assigned to your nginx-ingress-controller service.

```
export CLUSTER_NAME="tempest"

K8S_HOSTNAME=$(aws elbv2 describe-load-balancers --region us-east-1 --query "LoadBalancers[?LoadBalancerName==\`$CLUSTER_NAME-nlb\`].DNSName" --output text)
echo $K8S_HOSTNAME
```

* Create a vanity URL for the echo service. Make it an A ALIAS record that points to the $K8S_HOSTNAME found above.

```bash
ECHO_HOST="echo.david.va-oit.cloud"
```

* NOT WORKING! Route traffic directed at the `echo` subdomain within the cluster.

```
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1beta1
kind: Ingress
metadata:
  name: echo-ingress
  namespace: $NAMESPACE
  annotations:
    kubernetes.io/ingress.class: "public"
spec:
  rules:
  - host: $ECHO_HOST
    http:
      paths:
      - path: /
        backend:
          serviceName: echo
          servicePort: 80
EOF
```

* NOT WORKING! Call the echo service. It should return `silverargint`.

```bash
curl $ECHO_HOST
```

### Integrate With Let's Encrypt

* Define the email address to use.

```bash
export ACME_REGISTRATION_EMAIL=dmedinets@crimsongovernment.com
```

* Create Let's Encrypt Issuer for a development and production environments. The main difference is the ACME server URL.

```bash
kubectl apply -f - <<EOF
apiVersion: cert-manager.io/v1alpha2
kind: Issuer
metadata:
  name: letsencrypt-development-issuer
  namespace: $NAMESPACE
spec:
  acme:
    # The ACME server URL
    server: https://acme-staging-v02.api.letsencrypt.org/directory
    email: $ACME_REGISTRATION_EMAIL
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
    email: $ACME_REGISTRATION_EMAIL
    # Name of a secret used to store the ACME account private key
    privateKeySecretRef:
      name: letsencrypt-production-issuer
    # Enable the HTTP-01 challenge provider
    solvers:
    - http01:
        ingress:
          class: nginx
EOF
```

* Check on the status of the development issuer. But entries should be ready.

```
kubectl get issuer --namespace $NAMESPACE
```
