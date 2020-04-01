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

You can run one test just to make sure the software is installed and talking to the cluster correctly.

```
sonobuoy run --mode=quick --wait
```

## Run Conformance Test

This will take hours. Don't use the `--wait` parameter. Instead check for completion using `sonobuoy status` parameter.

```
sonobuoy run --mode=certified-conformance 
```

## Run CIS Benchmarks

This will take hours. Don't use the `--wait` parameter. Instead check for completion using `sonobuoy status` parameter.

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

## Example Results

Below are the results of running the CIS Benchmark on an AWS cluster of one master, two nodes, and several spot instances. Obviously, there are several issues that need remediation. Also, the timeouts are concerning.

Given that the client's cluster might be provided by Red Hat or an enterprise team, it might not be worthwhile to remediate all of the issues found. On the other hand, it is good to know what failed.

```
Plugin: kube-bench-master
Status: failed
Total: 1
Passed: 0
Failed: 1
Skipped: 0

Failed tests:
timeout waiting for results

Plugin: kube-bench-node
Status: failed
Total: 28
Passed: 11
Failed: 13
Skipped: 4

Failed tests:
4.1.1 Ensure that the kubelet service file permissions are set to 644 or more restrictive (Scored)
4.1.2 Ensure that the kubelet service file ownership is set to root:root (Scored)
4.1.8 Ensure that the client certificate authorities file ownership is set to root:root (Scored)
4.2.2 Ensure that the --authorization-mode argument is not set to AlwaysAllow (Scored)
4.2.4 Ensure that the --read-only-port argument is set to 0 (Scored)
4.2.6 Ensure that the --protect-kernel-defaults argument is set to true (Scored)
4.2.10 Ensure that the --tls-cert-file and --tls-private-key-file arguments are set as appropriate (Scored)
4.2.12 Ensure that the RotateKubeletServerCertificate argument is set to true (Scored)
timeout waiting for results
timeout waiting for results
timeout waiting for results
timeout waiting for results
timeout waiting for results
```

## Delete Resources

```
sonobuoy delete --wait
# wait for the namespace to delete.
```
