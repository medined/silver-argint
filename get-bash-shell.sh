#!/bin/bash

cat <<EOF > yaml/shell-demo.yaml
apiVersion: v1
kind: Pod
metadata:
  name: shell-demo
spec:
  volumes:
  - name: shared-data
    emptyDir: {}
  containers:
  - name: nginx
    image: nginx
    volumeMounts:
    - name: shared-data
      mountPath: /usr/share/nginx/html
  hostNetwork: true
  dnsPolicy: Default
EOF

kubectl apply -f yaml/shell-demo.yaml

kubectl get pod shell-demo

kubectl exec -it shell-demo -- /bin/bash

kubectl delete pod shell-demo
