#!/bin/bash

RANDOMIZER=$(uuid | cut -b-5)
POD_NAME="bash-shell-$RANDOMIZER"
IMAGE=centos

cat <<EOF > yaml/shell-demo.yaml
apiVersion: v1
kind: Pod
metadata:
  name: $POD_NAME
spec:
  containers:
  - name: $POD_NAME
    image: $IMAGE
    command: ["/bin/bash"]
    args: ["-c", "while true; do date; sleep 5; done"]
    env:
    - name: NODE_NAME
      valueFrom:
        fieldRef:
          fieldPath: spec.nodeName
  dnsPolicy: Default
  hostNetwork: true
  restartPolicy: Never
EOF

kubectl apply -f yaml/shell-demo.yaml

echo "---------------------------------"
echo "| Press ^C when pod is running. |"
echo "---------------------------------"

kubectl get pod $POD_NAME -w

echo

kubectl exec -it $POD_NAME -- /bin/bash

kubectl delete pod $POD_NAME
