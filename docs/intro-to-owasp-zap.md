# Introduction To OWASP-ZAP (OWASP Zed Attack Proxy)

## Description

OWASP Zed Attack Proxy (ZAP) is an open source tool performing pen testing on web applications and APIs. Pen testing a web application helps ensure that there are no security vulnerabilities hackers could exploit. It is the world's most popular free web security tool, actively maintained by a dedicated international team of volunteers.

This note shows how to perform an OWASP-ZAP test using a Kubernetes Job.

## Links

* https://www.zaproxy.org/
* https://github.com/zee-ahmed/kube-owasp-zap

## Manual Process

* Create a namespace.

```bash
kubectl apply -f -<<EOF
apiVersion: v1
kind: Namespace
metadata:
    name: owasp-zap
    labels:
        name: owasp-zap
EOF
```

* Add the Helm repository.

```bash
helm repo add simplyzee https://charts.simplyzee.dev
```

* Inspect the values used by the Helm cart.

```bash
helm inspect values simplyzee/kube-owasp-zap > yaml/kube-owasp-zap.values.yaml.original
cat yaml/kube-owasp-zap.values.yaml.original
```

* Designate which URL will be tested. Make sure to align the spider and recursive flags to the URL. For example, you probably don't want to spider a website like ibm.com.

```bash
TARGET_URL=https://www.ibm.com
```

* Start job. Note that job names must be unique. Adding a timestamp to the job name means they can be easily sorted later.


```bash
helm install "vuln-scan-$(date '+%Y-%m-%d-%H-%M-%S')-job" simplyzee/kube-owasp-zap \
    --namespace owasp-zap \
    --set zapcli.debug.enabled=true \
    --set zapcli.spider.enabled=false \
    --set zapcli.recursive.enabled=false \
    --set zapcli.targetHost=$TARGET_URL
```

* List the jobs. The newest jobs will be at the bottom of the list.

```bash
kubectl get job --namespace owasp-zap | grep -v "COMPLETIONS" | sort
vuln-scan-2020-03-20-10-46-14-job-kube-owasp-zap   1/1           33s        55m
vuln-scan-2020-03-20-11-10-17-job-kube-owasp-zap   1/1           22s        31m
```

* Log the job logs.

```bash
kubectl logs job/vuln-scan-2020-03-20-11-10-17-job-kube-owasp-zap --namespace owasp-zap
[INFO]            Starting ZAP daemon
[DEBUG]           Starting ZAP process with command: /zap/zap.sh -daemon -port 8080 -config api.disablekey=true.
[DEBUG]           Logging to /zap/zap.log
[DEBUG]           ZAP started successfully.
[INFO]            Running a quick scan for https://www.ibm.com
[DEBUG]           Disabling all current scanners
[DEBUG]           Enabling scanners with IDs 40012,40014,40016,40017,40018
[DEBUG]           Scanning target https://www.ibm.com...
[DEBUG]           Started scan with ID 0...
[DEBUG]           Scan progress %: 0
[DEBUG]           Scan #0 completed
[INFO]            Issues found: 0
[INFO]            Shutting down ZAP daemon
[DEBUG]           Shutting down ZAP.
[DEBUG]           ZAP shutdown successfully.
```
