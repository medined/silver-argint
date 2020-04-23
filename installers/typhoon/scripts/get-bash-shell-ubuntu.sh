#!/bin/bash

RANDOMIZER=$(uuid | cut -b-5)
POD_NAME="bash-shell-$RANDOMIZER"
IMAGE=ubuntu
NAMESPACE=$(uuid)

$HOME/bin/kubectl create namespace $NAMESPACE

$HOME/bin/kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: $POD_NAME
  namespace: $NAMESPACE
spec:
  containers:
  - name: $POD_NAME
    image: $IMAGE
    command: ["/bin/bash"]
    args: ["-c", "while true; do date; sleep 5; done"]
  hostNetwork: true
  dnsPolicy: Default
  restartPolicy: Never
EOF

echo "---------------------------------"
echo "| Press ^C when pod is running. |"
echo "---------------------------------"

$HOME/bin/kubectl -n $NAMESPACE get pod $POD_NAME -w

echo

$HOME/bin/kubectl -n $NAMESPACE exec -it $POD_NAME -- /bin/bash

$HOME/bin/kubectl -n $NAMESPACE delete pod $POD_NAME
$HOME/bin/kubectl delete namespace $NAMESPACE
