# Deploy Dashboard

There is a standard Dashboard that provides great insight into the workings of a cluster. However, it is not installed by default.

Learn more about the dashboard at https://github.com/kubernetes/dashboard.

An installed dashboard does not have an endpoint exposed on the internet. This would provide an attack surface for hackers. Instead, you open a local proxy on port 8081 and use localhost.

## Scripted Process

The `dashboard-proxy-start.sh` will install the dashboard and start the proxy as a background process. The `dashboard-proxy-stop.sh` script will kill the proxy. If you are using a laptop, you may need to stop and the start after your laptop suspends. 

```
./dashboard-proxy-start.sh
./dashboard-proxy-stop.sh
```

## Manual Process

* Appy the manifest.

```
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0-beta8/aio/deploy/recommended.yaml
```

* Create the admin-user service account.

```
kubectl apply -f - <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kubernetes-dashboard
EOF
```

* Create a cluser role binding.

```
kubectl apply -f - <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: admin-user
  namespace: kubernetes-dashboard
EOF
```

* Get a login bearer token. Copy the token and paste it into the login screen. You could also run `get-login-token.sh`.

```
kubectl -n kubernetes-dashboard describe secret $(kubectl -n kubernetes-dashboard get secret | grep admin-user | awk '{print $1}')
```

* Start the proxy. This forwards local http requests to the remote cluster.

```
kubectl proxy
```

* Visit the following link to see the dashboard.

```
http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/
```
