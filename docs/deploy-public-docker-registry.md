# Deploy Public Docker Registry

## Links

* Harbor
 * https://goharbor.io/
 * https://demo.goharbor.io/
 * https://github.com/goharbor/harbor/tree/master/docs/1.10
 * https://github.com/goharbor/harbor/blob/master/docs/1.10/install-config/harbor-ha-helm.md
* Docker Registry
 * https://hub.helm.sh/charts/stable/docker-registry
 * https://www.nearform.com/blog/how-to-run-a-public-docker-registry-in-kubernetes/
 * https://www.digitalocean.com/community/tutorials/how-to-set-up-a-private-docker-registry-on-top-of-digitalocean-spaces-and-use-it-with-digitalocean-kubernetes

### Harbor

* remote registry - proxy to Docker Hub.
* demonstrate vulnerability report.
* create developer member.

### Docker Registry

#### Helm

* Install registry using Helm.

```
helm install stable/docker-registry --generate-name
```

* Get Helm name.

```
HELM_NAME=$(helm list | grep "docker-registry" | cut -f1)
```

* Get url.

```
export POD_NAME=$(kubectl get pods --namespace default -l "app=docker-registry,release=$HELM_NAME" -o jsonpath="{.items[0].metadata.name}")
kubectl -n default port-forward $POD_NAME 8080:5000
```

* Visit http://127.0.0.1:8080.

#### Custom Deployment

* https://www.nearform.com/blog/how-to-run-a-public-docker-registry-in-kubernetes/

