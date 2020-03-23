# Research Topics

As interesting topics are explored, turn them into documents or scripts.

* https://www.jeffgeerling.com/blog/2020/kubernetes-collection-ansible
* https://github.com/ansible/community/wiki/Kubernetes
* https://medium.com/faun/deploying-and-scaling-jenkins-on-kubernetes-2cd4164720bd
* https://bitnami.com/stack/jenkins/helm
* https://www.devtech101.com/2019/06/18/installing-jenkins-on-your-kubernets-cluster-by-using-helm-charts - pull values out of helm definition.
* https://hub.helm.sh/charts/codecentric/jenkins - a bit better than the 'stable' version.
* https://itnext.io/dynamic-jenkins-agent-from-kubernetes-4adb98901906
* https://www.magalix.com/blog/magalix-kubernetes-101-series-0
* https://www.magalix.com/blog/kubernetes-patterns-the-reflection-pattern
* https://kubernetes.io/docs/tasks/inject-data-application/downward-api-volume-expose-pod-information/
* https://www.youtube.com/watch?v=qmDzcu5uY1I
* https://k3s.io/
* wildcard subdomain in route53?
* https://www.alibabacloud.com/blog/kubernetes-volume-basics-emptydir-and-persistentvolume_594834

* https://cloudowski.com/articles/why-vault-and-kubernetes-is-the-perfect-couple/

https://www.youtube.com/channel/UCvqbFHwN-nwalWPjPUKpvTA/playlists - Cloud Native Cloud Formation

https://www.youtube.com/watch?v=90kZRyPcRZw - Kubernetes Deconstructed: Understanding Kubernetes by Breaking It Down
https://www.youtube.com/watch?v=YjZ4AZ7hRM0 - How the Department of Defense Moved to Kubernetes and Istio
https://www.youtube.com/watch?v=ZuIQurh_kDk - Kubernetes Design Principles: Understand the Why

https://bit.ly/k8sdoesk8s - che in kubernetes

Container Attached Storage - CAS

https://kustomize.io/ - one yaml file to manage dev, test, and prod

connect jenkins to private registry  in k8s.

https://github.com/aquasecurity/kube-bench - Checks whether Kubernetes is deployed according to security best practices as defined in the CIS Kubernetes Benchmark 
https://github.com/aquasecurity/kube-hunter - securtiy weaknesses

https://github.com/grafana/cortex-jsonnet

source <(kubectl completion bash)

export KUBE_EDITOR=`code --wait`
kubectl edit deployment nginx

kubectl explain pod
kubectl explain pod --recursive

kubectl get --raw /
kubectl get --raw /api

Log Levels
-v=9 curl command
-v=8 request and response body
-v=6 method and apipath

#powerofkubectl

scanning and signing images in docker registry
allocate resource limits

simple example to show how secret is injected into container as files

distroless - for nodejs because bash or shell does not exist.

If the developer creates a docker image, then no build is needed on jenkins? Then how are unit tests run? Maybe jenkins builds the docker image after tests?

trivy, clair, notary, tuf, in-toto, falco, open policy agent - security tools

harbor + trivy - good match

dive - dive into details of docker image. can look at file tree at each layer.

tracee - visibility in system calls by the container

knative

kubectl get pods -w in separate terminal window to watch pods start and pod for video.

kubectl get pods-o wide

HIPPA Compliance
https://containerjournal.com/topics/container-security/best-practices-for-hipaa-compliance-in-a-containerized-environment/

https://www.threatstack.com/blog/aws-hipaa-compliance-best-practices-checklist

EKS HIPPA Options
https://github.com/opszero/auditkube

NIST Benchmarks 
https://nvd.nist.gov/ncp/checklist/766

API for stable CoreOS version 
https://coreos.com/dist/aws/aws-stable.json

curl -s https://coreos.com/dist/aws/aws-stable.json | jq -r '.["us-east-1"].hvm' will get the HVM AMI ID in us-east-1
or
Similarly, setting an ENV VAR or in a shell script 
AMI_ID=`curl -s https://coreos.com/dist/aws/aws-stable.json | jq -r '.["us-east-1"].hvm’`

## Notes

* https://www.oit.va.gov/library/recurring/edp/ - the team behind the kubernetes research.

## Research

* https://medium.com/faun/how-to-setup-a-perfect-kubernetes-cluster-using-kops-in-aws-b616bdfae013 - cluster with 3 master nodes and 2 worker nodes with 1 AWS On-demand instance and 1 AWS Spot instance within a private topology with multi-availability zones deployment.
* https://garden.io/ - garden automates the repetitive parts of your workflow to make developing for Kubernetes and cloud faster and easier.
* https://okteto.com/ - Development platform for Kubernetes applications. Build better applications by developing and testing your code directly in Kubernetes.
* https://blog.alexellis.io/a-bit-of-istio-before-tea-time/ - Istio demo up and running with a public IP directly to your laptop.
* https://www.youtube.com/watch?v=8JbGfNNG1mQ - kubernetes team live stream
* https://github.com/kubernetes-sigs/kubespray - Deploy a Production Ready Kubernetes Cluster
* https://kind.sigs.k8s.io/ - running local Kubernetes clusters using Docker container “nodes”.

On Mon, Mar 9, 2020 at 8:21 PM David Medinets <david.medinets@gmail.com> wrote:
* DistroLess
  * https://github.com/GoogleContainerTools/distroless
  * https://www.abhaybhargav.com/stories-of-my-experiments-with-distroless-containers/

https://aws.amazon.com/compliance/services-in-scope/
https://turbot.com/
https://www.telerik.com/teststudio
https://www.mitre.org/publications/project-stories/synthetic-patient-records-help-deliver-real-health-outcomes
https://nvlpubs.nist.gov/nistpubs/SpecialPublications/NIST.SP.800-190.pdf
https://www.gao.gov/assets/710/702642.pdf
http://trm.oit.va.gov/ToolRequestPage.aspx?treqid=52855
https://vaww.vashare.oit.va.gov/sites/OneVaEa/DevOps/Shared%20Documents/Technical%20Architecture%20References/Selecting%20the%20Optimal%20Technical%20Architecture%20for%20Data%20Ingestion.pdf

### Kubernetes

* https://operatorhub.io/
* https://cluster-api.sigs.k8s.io/


Shared and Federated Promethus Servers - 683 views - 1 year ago

 
https://jenkins-x.io/docs/getting-started/
  jx install for existing cluster.
  private git repositories?
  will this work with artifactory?
  https://www.youtube.com/watch?v=uHe7R_iZSLU

https://github.com/solarhess/jenkins_kube_brains
  - docker creates files in /var/lib/docker which is in a small volume on AWS instance? 9 minutes into video.
  - corporate network and k8s share private address space (10.0, 172,16, 192.168). This cause a problem. 11:30 min
  - test disk io - 15:30 min
  - repeatable config - 16 min - backup job for JENKINS HOME - and restore job. Simply then writing groovy config jobs.
  - prune docker resources hourly - 23 min
  - have different size instance groups to lets job be sized to node. 26 min

ksync - sync laptop with k8s cluster. 

anti-affinity deployment - preferredDuringSchedulingIgnoredDuringExecution


aws encryption provider - kms at rest. - removes encryption from applicatio control - hard to make mistake - can't make configuration error to expose credentials.

https://github.com/kubernetes-sigs/kube-batch - A batch scheduler of kubernetes for high performance workload.
https://github.com/PaddlePaddle/cloud - PaddlePaddle Cloud is a combination of PaddlePaddle and Kubernetes. It supports fault-recoverable and fault-tolerant large-scaled distributed deep learning.

https://github.com/datawire/kubernaut

https://github.com/grafeas/kritis - Deploy-time Policy Enforcer for Kubernetes applications. Binary Authorization allows stakeholders to ensure that deployed software artifacts have been prepared according to organization’s standards.

https://www.datawire.io/

LOCAL DEVELOPING
https://www.telepresence.io/ - FAST, LOCAL DEVELOPMENT FOR KUBERNETES AND OPENSHIFT MICROSERVICES

CI/CD
https://argoproj.github.io/argo-cd/

https://grafeas.io/ - An open artifact metadata API to audit and govern your software supply chain

https://kubesec.io/ - Security risk analysis for Kubernetes resources
https://github.com/IBM/portieris - A Kubernetes Admission Controller for verifying image trust with Notary.

https://docs.fluxcd.io/en/1.18.0/ - https://github.com/bricef/gitops-tutorial - Flux is a tool that automates the deployment of containers to Kubernetes. It fills the automation void that exists between building and monitoring.

https://github.com/kubernetes-sigs/kube-batchhttps://www.cisecurity.org/cis-benchmarks/#kubernetes1.5.0

https://github.com/kubernetes/test-infra/tree/master/prow/cmd/peribolos - Peribolos allows the org settings, teams and memberships to be declared in a yaml file. GitHub is then updated to match the declared configuration.

https://github.com/kubernetes/test-infra/tree/master/prow - Prow is a Kubernetes based CI/CD system. Jobs can be triggered by various types of events and report their status to many different 
services. In addition to job execution, Prow provides GitHub automation in the form of policy enforcement, chat-ops via /foo style commands, and automatic PR merging.

https://github.com/Comcast/kuberhealthy - An operator for synthetic monitoring on Kubernetes. Write your own tests in your own container and Kuberhealthy will manage everything else.

https://gitkube.sh/ - https://www.youtube.com/watch?v=gDGT4Gf_4JM - developers use pre-commit hook to deploy.
https://kubeapps.com/
https://github.com/dexidp/dex - OpenID Connect - use Google, GitHub, etc to login into Kubernetes cluster?
Add "Open Policy Agent" to pipeline which requires resource limits. Or as a github push check.
Example of ElasticSearch & Kibana.
WordPress, Joomla
use git hash for image version number for automation. Not sequential.
Security - internet-facing cluster and internal-facing cluster - to isolate CVE, limit breach fallout.
anonymouse-auth=false - disable for api server
load balancer reduces attack service since it is an AWS resource instead of code running on an EC2 cluster. This is more secure.
pop security policies (PSP)
audit logs of api server - who did what and when - audit policy
patroni - HA daemon
passing information into container using configmap - https://www.youtube.com/watch?v=E8uGIeiaaUQ - common configmap across resources
https://github.com/kubernetes-sigs/bootkube - self-hosted k8s
csysdig - important debugging! - F2 to see views - from https://www.youtube.com/watch?v=agbBy1Aduew - good for article. integration with k8s.
https://stackstorm.com/ - Robust Automation Engine - From simple if/then rules to complicated workflows, StackStorm lets you automate DevOps your way.
ceph - what benefit?
hystrix dashboard - different kinds of circuit breakers.
turbine dashbaord - what is it?
pachyderm.io - alternative to hadoop - open source, distributing processing framework
http://www.chronix.io/ - A fast and efficient time series storage
https://zipkin.io - Zipkin is a distributed tracing system. It helps gather timing data needed to troubleshoot latency problems in service architectures. 
https://github.com/grafana/loki - Loki is a horizontally-scalable, highly-available, multi-tenant log aggregation system inspired by Prometheus.
Use Apache Ignite to do session synchronization - https://www.youtube.com/watch?v=yB6Zl8nqqqE - 29mins
https://spiffe.io/ - https://www.youtube.com/watch?v=ikmxZdZRTio - Secure Production Identity Framework for Everyone - 
https://github.com/square/ghostunnel - Ghostunnel is a simple TLS proxy with mutual authentication support for securing non-TLS backend applications.
Request Enrichment
https://www.solo.io/open-source/ - 
https://squash.solo.io/ - https://www.youtube.com/watch?v=5TrV3qzXlgI - microservice debugging in k8s.
https://kubeval.instrumenta.dev/ - Kubeval is used to validate one or more Kubernetes configuration files, and is often used locally as part of a development workflow as well as in CI pipelines.
https://github.com/vapor-ware/kubetest - https://kubetest.readthedocs.io/en/latest/ - run tests (assertions) against configuration files.

https://projectcontour.io/ - Contour is an open source Kubernetes ingress controller providing the control plane for the Envoy edge and service proxy. Contour supports dynamic configuration updates and multi-team ingress delegation out of the box while maintaining a lightweight profile.

https://www.envoyproxy.io/ - ENVOY IS AN OPEN SOURCE EDGE AND SERVICE PROXY, DESIGNED FOR CLOUD-NATIVE APPLICATIONS

https://brigade.sh/ - Brigade is a tool for running scriptable, automated tasks in the cloud — as part of your Kubernetes cluster.

MESSAGING
https://nats-io.github.io/k8s/

Kubernetes/Ingress-Nginx is based on Nginxinc/Kubernetes-Ingress

SECURE PODS
https://www.youtube.com/watch?v=GLwmJh-j3rs = 6:00 - seccomp and apparmor annotations.
gVisor - emulated kernal - from google
kata containers - run in any k8s
ls /var/run/secrets/kubernetes.io/serviceaccount - using the default mounted ServiceAccount token?

https://www.youtube.com/watch?v=qs48vF36R-8
  3:20m - PodSecurityPolicy yaml

https://github.com/jelmersnoeck/barbossa - last change nearly two years ago. Kubernetes Chief Mate - Ensure the Safety and Security of your Applications.

STORAGE
https://min.io/ - S3-compatible object storage in k8s.
https://rook.io/ - https://www.youtube.com/watch?v=6p0GKjrYzg4 - https://www.youtube.com/watch?v=To1ldyb_9NA - Rook storage for kubernetes - Rook turns distributed storage systems into self-managing, self-scaling, self-healing storage services. It automates the tasks of a storage administrator: deployment, bootstrapping, configuration, provisioning, scaling, upgrading, migration, disaster recovery, monitoring, and resource management.

data-dog/godog - enables english in user stories
openebs/litmus - bridge between users and kubernetes

HIPPA Compliance
https://containerjournal.com/topics/container-security/best-practices-for-hipaa-compliance-in-a-containerized-environment/

https://www.threatstack.com/blog/aws-hipaa-compliance-best-practices-checklist

EKS HIPPA Options
https://github.com/opszero/auditkube

* NIST
  * https://www.youtube.com/watch?v=AqoDQaeuLXY - NIST Container Security Standards
  * Containers
    * https://nvlpubs.nist.gov/nistpubs/SpecialPublications/NIST.SP.800-190.pdf
  * Benchmarks 
    * https://nvd.nist.gov/ncp/checklist/766

API for stable CoreOS version 
https://coreos.com/dist/aws/aws-stable.json

curl -s https://coreos.com/dist/aws/aws-stable.json | jq -r '.["us-east-1"].hvm' will get the HVM AMI ID in us-east-1
or
Similarly, setting an ENV VAR or in a shell script AMI_ID=`curl -s https://coreos.com/dist/aws/aws-stable.json | jq -r '.["us-east-1"].hvm’`

* Test Data As A Service

* https://in-toto.io - a framework to secure the integrity of software supply chains. 

DATABASE 

https://vitess.io/ - massively scalable MySQL.

* SERVERLESS
    * https://fission.io - https://www.youtube.com/watch?v=9hiOn9YJzFw - Open source, Kubernetes-native Serverless Framework - !!! No need to build image !!! 
    * https://www.openfaas.com/
    * https://knative.dev/ - 
* Miscellaneous
    * https://github.com/Shopify/krane - A command-line tool that helps you ship changes to a Kubernetes namespace and understand the result
    * https://get-kapp.io/ -  kapp is a simple deployment tool focused on the concept of "Kubernetes application" — a set of resources with the same label.
    * https://fluxcd.io/ -  The GitOps operator for Kubernetes
    * https://kubesec.io/ - Security risk analysis for Kubernetes resources
    * https://kudo.dev/ - The Kubernetes Universal Declarative Operator
    * https://troubleshoot.sh/ - Deliver More Reliable and Predictable Kubernetes Applications
    * https://www.serverlab.ca/tutorials/development/nodejs/containerizing-a-node-js-rest-api-for-kubernetes/ - how to handle backend secrets.
    * https://kubecloud.com - the true learn-by-doing platform.
    * https://www.youtube.com/watch?v=80Ew_fsV4rM - Kubernetes Ingress Tutorial for Beginners | simply explained
    * https://github.com/slipway-gitops/slipway - GitOps by Commit Hash
    * https://skaffold.dev - Skaffold handles the workflow for building, pushing and deploying your application, allowing you to focus on what matters most: writing code
        * https://caylent.com/kubernetes-development-in-real-time-with-skaffold
    * https://tech.goglides.com/2020/03/13/stop-using-kubeconfig-with-admin-access
    * https://litmuschaos.io - cloud-native chaos engineering for kubernetes developers
    * https://containo.us/maesh/ - Maesh is a straight-forward, easy to configure, and non-invasive service mesh that allows visibility and management of the traffic flows inside any Kubernetes cluster.

* API Gateway
    * Ambassador Edge Stack - Easily expose, secure, and manage traffic to your Kubernetes microservices of any type
        * https://www.getambassador.io/
* Load Testing
    * Locust - An open source load testing tool. - Define user behaviour with Python code, and swarm your system with millions of simultaneous users.
        * https://locust.io/
        * https://medium.com/locust-io-experiments/locust-io-experiments-running-in-kubernetes-95447571a550
        * https://github.com/joakimhew/locust-kubernetes
        * https://github.com/asatrya/locust_k8s
        * https://cloud.google.com/solutions/distributed-load-testing-using-gke
* Security
    * https://www.modsecurity.org/ - ModSecurity - open source web application firewall (WAF)
        * https://coreruleset.org/ - OWASP ModSecurity Core Rule Set v3.0
* System Administration
    * kured - Kured (KUbernetes REboot Daemon) is a Kubernetes daemonset that performs safe automatic node reboots. It gets triggered by the package management system of the underlying OS. 
