# Deploy Nginx

* Start a deployment.

```
kubectl run  --generator=run-pod/v1 nginx --image nginx --port 80
```

* Export nginx using a load balancer.

```
kubectl expose deployment nginx --type LoadBalancer --port 80
```

* Find the load balancer hostname.

```
kubectl get service nginx
```

* Using `dig` to wait for DNS propagation.

```
dig <load-balancer-hostname>
```

* Visit the home page.

```
curl <load-balancer-hostname>
```

* Delete the resources.

```
kubectl delete service/nginx pod/nginx
```
