# Deploy Ingress Controller

By default, pods of Kubernetes services are not accessible from the external network, but only by other pods within the Kubernetes cluster. Kubernetes has a built‑in configuration for HTTP load balancing, called Ingress, that defines rules for external connectivity to Kubernetes services. Users who need to provide external access to their Kubernetes services create an Ingress resource that defines rules, including the URI path, backing service name, and other information. **The Ingress controller can then automatically program a front‑end load balancer to enable Ingress configuration.** The NGINX Ingress Controller for Kubernetes is what enables Kubernetes to configure NGINX and NGINX Plus for load balancing Kubernetes services.

## NGINX Ingress Controller for Kubernetes

The NGINX Ingress Controller for Kubernetes provides enterprise‑grade delivery services for Kubernetes applications. With the NGINX Ingress Controller for Kubernetes, you get basic load balancing, SSL/TLS termination, support for URI rewrites, and upstream SSL/TLS encryption. NGINX Plus users additionally get session persistence for stateful applications and JSON Web Token (JWT) authentication for APIs.

## Links

* https://www.nginx.com/products/nginx/kubernetes-ingress-controller/

## Procedure

All resources for the ingress-controller are created using manifests which makes the installation process just one line.

```bash
kubectl apply -R -f ingress-controller
```

There are some things to note about the manifests.

>The `nginx-ingress-controller-deployment` deployment pulls v0.30.0 of its image. Check https://quay.io/repository/kubernetes-ingress-controller/nginx-ingress-controller?tab=tags for the latest `nginx-ingress-controller` tag.

>The `nginx-ingress-controller-deployment` should respond to :10254/healthz to make the target group health check happy.

>The `--ingress-class=public` parameter is commented out because I don't understand it enough. I think when it is used, then the Ingress resource needs to have the `kubernetes.io/ingress.class: public` annotation. However, this might conflict with the `http01` solver in some way. For now, it is not worth figuring out.

>The CPU and Memory resource limits are completely arbitary and have no reflection of real-world use. In a production environment, make sure to monitor.

* The following resources are created.
  * 0-rbac
    * Namespace: `ingress`
    * ServiceAccount: `nginx-ingress-serviceaccount`
    * ClusterRole: `nginx-ingress-clusterrole`
    * Role: `nginx-ingress-role`
    * RoleBinding: `nginx-ingress-role-nisa-binding`
    * ClusterRoleBinding: `nginx-ingress-clusterrole-nisa-binding`
  * 1-default-backend
    * Deployment: `default-http-backend`
    * Service: `default-http-backend-service`
  * 2-deployment
    * Deployment: `nginx-ingress-controller-deployment`
  * 3-service
    * Service: `nginx-ingress-controller-service`
