# Troubleshooting

## SSL Certificate Request Not Completing

### Did Not Get Expected Response

```
E0414 03:28:58.803729 1 sync.go:184] cert-manager/controller/challenges 
"msg"="propagation check failed" "error"="did not get expected response when 
querying endpoint, expected \"jz-p2oPwN0RtkRpczhDoIbzxmRDLgnc8pgUJYN5xjks.9nYOupYS4HDX0r9ug3iojMZfg1Ec7rGpSviUlalcM7s\" 
but got: silverargint\n" 
"dnsName"="text-responder.david.va-oit.cloud" "resource_kind"="Challenge" 
"resource_name"="text-responder-tls-3425851964-881250344-3109647009" 
"resource_namespace"="text-responder" "type"="http-01"
```

## Server misbehaving

I recieved this message when my internet connection was down. When the connection came back, the error went away.

## Machine X has not yet joined cluster

Check the route table associated with the machine's subnet. Make sure that it has an Internet Gateway (IGW) in the target list.

## No matches for kind "X" in version "Y"

You'll run into this issue when the `apiVersion` and the `kind` in your manifest yaml file are not supported. Typically this is seem when documentation (or articles) are out-of-date.

For a specific example, the following is wrong.

```
apiVersion: extensions/v1beta1
kind: PodSecurityPolicy
```

To resolve this issue, use `kubectl explain` with the `kind` as shown below. You'll see that the correct `apiVersion` is `policy/v1beta1`.

```
kubectl explain PodSecurityPolicy | grep VERSION
```

## The server doesn't have a resource type "podSecurityPolicies"

PSP needs to be enabled on your cluster. If the following command responds with `the server doesn't have a resource type "podSecurityPolicies"` then you need to research how to enable PSP for your cluster. The exact enablement process depends on how your cluster was created.

```
kubectl get podsecuritypolicies
```
