# Deploy Dashboard

## Steps

* Appy the manifest.

```
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0-beta8/aio/deploy/recommended.yaml
```

* Create the admin-user service account.

```
cat <<EOF > yaml/dashboard-adminuser.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kubernetes-dashboard
EOF
kubectl apply -f yaml/dashboard-adminuser.yaml
```

* Create a cluser role binding.

```
cat <<EOF > yaml/dashboard-adminuser-clusterrolebinding.yaml
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
kubectl apply -f yaml/dashboard-adminuser-clusterrolebinding.yaml
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
