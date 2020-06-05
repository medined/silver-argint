#!/bin/bash

RANDOMIZER=$(uuid | cut -b-5)
POD_NAME="bash-shell-$RANDOMIZER"
IMAGE=centos
NAMESPACE=$(uuid)

SECRET_FILE=/tmp/bash-shell-secret.txt
if [ ! -f $SECRET_FILE ]; then
  uuid > $SECRET_FILE
fi

kubectl create namespace $NAMESPACE
kubectl -n $NAMESPACE create configmap greek-gyro --from-literal=onions=no
kubectl -n $NAMESPACE create secret generic bash-shell-secret --from-file=$SECRET_FILE

kubectl apply -f - <<EOF
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
    env:
    - name: NODE_NAME
      valueFrom:
        fieldRef:
          fieldPath: spec.nodeName
    - name: ONIONS
      valueFrom:
        configMapKeyRef:
          name: greek-gyro
          key: onions
    - name: BASH_SHELL_SECRET
      valueFrom:
        secretKeyRef:
          name: bash-shell-secret
          key: bash-shell-secret.txt
    volumeMounts:
    - name: bash-shell-secret
      mountPath: /config/bash-shell-secret
      readOnly: true
    - name: greek-gyro-volume
      mountPath: /config/greek-gyro
      readOnly: true
  dnsPolicy: Default
  hostNetwork: true
  restartPolicy: Never
  volumes:
  - name: greek-gyro-volume
    configMap:
      name: greek-gyro
  - name: bash-shell-secret
    secret:
      secretName: bash-shell-secret
EOF

echo "---------------------------------"
echo "| Press ^C when pod is running. |"
echo "---------------------------------"

kubectl -n $NAMESPACE get pod $POD_NAME -w

echo

echo "| FILES"
echo "|   /config/greek-gryo"
echo "|   /config/bash-shell-secret/bash-shell-secret.txt"
echo
echo "| ENVIRONMENT VARIABLES"
echo "|   BASH_SHELL_SECRET"
echo "|   NODE_NAME is availabe as an environment variable."
echo "|   ONIONS is availabe as an environment variable."
echo

kubectl -n $NAMESPACE exec -it $POD_NAME -- /bin/bash
kubectl -n $NAMESPACE delete pod $POD_NAME
kubectl -n $NAMESPACE delete configmap greek-gyro
kubectl -n $NAMESPACE delete secret bash-shell-secret
kubectl delete namespace $NAMESPACE

rm -f $SECRET_FILE
