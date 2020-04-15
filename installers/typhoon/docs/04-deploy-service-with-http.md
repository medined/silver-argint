# Deploy Service With HTTP

## Prerequisites

* Set the namespace and host for the service to be deployed later.

```bash
NAMESPACE=text-responder
TEXT_RESPONDER_HOST="text-responder.david.va-oit.cloud"
```

* Create a namespace.

```bash
kubectl apply -f - <<EOF
apiVersion: v1
kind: Namespace
metadata:
    name: $NAMESPACE
    labels:
        name: $NAMESPACE
EOF
```

* Set the `kubectl` context so that $NAMESPACE is the current namespace. Undo this action by using `default` as the namespace.

```bash
kubectl config set-context --current --namespace=$NAMESPACE
```

## Deploy text-responder Application

The service being deployed just returns "silverargint" as a text response. Its simplicity makes it a great for this kind of preliminary exploration.

* Deploy a small web server that returns a text message. 

```bash
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: text-responder
  namespace: $NAMESPACE
spec:
  selector:
    matchLabels:
      app: text-responder
  replicas: 2
  template:
    metadata:
      labels:
        app: text-responder
    spec:
      containers:
      - name: text-responder
        image: hashicorp/http-echo
        args:
        - "-text=silverargint"
        ports:
        - containerPort: 5678
---
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
    app: text-responder
EOF
```

* The following resources now exist. Your pods and replicaset will be differenty named.

```
deployment.apps/text-responder
replicaset.apps/text-responder-bcdd88f9d
pod/text-responder-bcdd88f9d-d7w9h
pod/text-responder-bcdd88f9d-vjxff
service/text-responder
```

* Check the service is running. You should see the `text-responder` service in the list.

```bash
kubectl get service --namespace $NAMESPACE
```

* Get the load balancer hostname assigned to your ingress service.

```bash
export CLUSTER_NAME="tempest"

K8S_HOSTNAME=$(aws elbv2 describe-load-balancers --region us-east-1 --query "LoadBalancers[?LoadBalancerName==\`$CLUSTER_NAME-nlb\`].DNSName" --output text)
echo $K8S_HOSTNAME
```

* Create a vanity URL for the echo service. The URL will be $TEXT_RESPONDER_HOST that was defined above. Make it an A ALIAS record that points to the $K8S_HOSTNAME found above.

* Test the hostname.

```bash
dig $TEXT_RESPONDER_HOST
```

* Curl should get the default 404 response.

```bash
curl http://$TEXT_RESPONDER_HOST
```

```bash
curl https://$TEXT_RESPONDER_HOST
```

* Route traffic directed at the `text-responder` subdomain within the cluster.

```bash
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1beta1
kind: Ingress
metadata:
  name: text-responder-ingress
  namespace: $NAMESPACE
#  annotations:
#    kubernetes.io/ingress.class: public
spec:
  rules:
  - host: $TEXT_RESPONDER_HOST
    http:
      paths:
      - backend:
          serviceName: text-responder
          servicePort: 80
EOF
```

* Call the service. It should return `silverargint`.

```
curl http://$TEXT_RESPONDER_HOST
```
