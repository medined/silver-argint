# Run a Shell Inside the Cluster

* Create a manifest file.

```
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
```

* Apply the manifest

```
kubectl apply -f yaml/shell-demo.yaml
```

* Verify the pod  is running.

```
kubectl get pod shell-demo
```

* Get a shell in the pod.

```
kubectl exec -it shell-demo -- /bin/bash
# do whatever
exit
```

* Kill the pod.

```
kubectl delete pod shell-demo
```
