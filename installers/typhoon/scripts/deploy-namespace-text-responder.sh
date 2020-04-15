#!/bin/bash

#####
# Deploy the text-responder service.

NAMESPACE=text-responder
TEXT_RESPONDER_HOST="text-responder.david.va-oit.cloud"

kubectl apply -f - <<EOF
apiVersion: v1
kind: Namespace
metadata:
    name: $NAMESPACE
    labels:
        name: $NAMESPACE
---
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
---
apiVersion: networking.k8s.io/v1beta1
kind: Ingress
metadata:
  name: text-responder-ingress
  namespace: $NAMESPACE
  annotations:
    kubernetes.io/ingress.class: nginx
spec:
  rules:
  - host: $TEXT_RESPONDER_HOST
    http:
      paths:
      - backend:
          serviceName: text-responder
          servicePort: 80
        path: "/"
EOF

# wait for resources to start.
sleep 5

echo
echo "curl http://$TEXT_RESPONDER_HOST"
curl http://$TEXT_RESPONDER_HOST
