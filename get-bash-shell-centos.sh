#!/bin/bash

RANDOMIZER=$(uuid | cut -b-5)
POD_NAME="bash-shell-$RANDOMIZER"
IMAGE=centos

SECRET_FILE=/tmp/bash-shell-secret.txt
if [ ! -f $SECRET_FILE ]; then
  uuid > $SECRET_FILE
fi

$HOME/bin/kubectl create configmap greek-gyro --from-literal=onions=no
$HOME/bin/kubectl create secret generic bash-shell-secret --from-file=$SECRET_FILE

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

$HOME/bin/kubectl apply -f yaml/shell-demo.yaml

echo "---------------------------------"
echo "| Press ^C when pod is running. |"
echo "---------------------------------"

$HOME/bin/kubectl get pod $POD_NAME -w

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

$HOME/bin/kubectl exec -it $POD_NAME -- /bin/bash
$HOME/bin/kubectl delete pod $POD_NAME
$HOME/bin/kubectl delete configmap greek-gyro
$HOME/bin/kubectl delete secret bash-shell-secret

rm -f $SECRET_FILE
