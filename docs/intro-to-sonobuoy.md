# Introduction To Sonobuoy

## Description

Sonobuoy is a diagnostic tool that makes it easier to understand the state of a Kubernetes cluster by running a choice of configuration tests in an accessible and non-destructive manner.

Given that there are many ways to create Kubernetes clusters and many environments used to host them, those tasked with maintaining a cluster are often left wondering whether it is ‘correct’. Is it properly configured? Does it work as it should?

Sonobuoy is a diagnostic tool that aims to address these questions. Sonobuoy makes it easier to understand the state of a Kubernetes cluster by running a set of Kubernetes conformance tests in an accessible and non-destructive manner. Its diagnostics provide a customizable, extendable, and cluster-agnostic way to generate clear, informative reports about your cluster, regardless of your deployment details.

## Tags

compliance, diagnostic, configuration, testing

## Links

* https://sonobuoy.io/

## Installation

```
curl -L -o /tmp/sonobuoy.tgz https://github.com/vmware-tanzu/sonobuoy/releases/download/v0.17.2/sonobuoy_0.17.2_linux_amd64.tar.gz
tar xf /tmp/sonobuoy.tgz
mv ./sonobuoy $HOME/bin
rm -f /tmp/sonobuoy.tgz
```

## Run One Test

```
sonobuoy run --mode=quick --wait
```

## Run Conformance Test

This will take hours. Don't use the `--wait` parameter. Instead check for completion using the `status` parameter.

```
sonobuoy run --mode=certified-conformance 

sonobuoy status
```

## Run CIS Benchmarks

```
sonobuoy run \
  --plugin https://raw.githubusercontent.com/vmware-tanzu/sonobuoy-plugins/master/cis-benchmarks/kube-bench-plugin.yaml \
  --plugin https://raw.githubusercontent.com/vmware-tanzu/sonobuoy-plugins/master/cis-benchmarks/kube-bench-master-plugin.yaml

sonobuoy status
```

## Get the Results

```
RESULTS=$(sonobuoy retrieve)
sonobuoy results $RESULTS
```

## Delete Resources

```
sonobuoy delete --wait
# wait for the namespace to delete.
```


$ kubectl wait --for=condition=Available deployment/cert-manager-webhook -n cert-manager
deployment.extensions/cert-manager-webhook condition met

kubectl wait --for=delete namespace/sonobuoy
