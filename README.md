# Introduction

This project documents my exploration into [kubernets](https://kubernetes.io/). Each goal shown below is fairly simple and intended to be short and declarative. You'll need to read the orginal source material by following the links in each article to learn context.

Before reading any of the material here, I suggest the short courses at katacoda.com. You can click on the shell commands in order to run them.

* https://www.youtube.com/watch?v=PH-2FfFD2PU - Concepts in 5 minutes
* https://cloud.google.com/kubernetes-engine/kubernetes-comic
* https://medium.com/google-cloud/kubernetes-nodeport-vs-loadbalancer-vs-ingress-when-should-i-use-what-922f010849e0
* https://www.katacoda.com/courses/kubernetes/launch-single-node-cluster
* https://www.katacoda.com/courses/kubernetes/kubectl-run-containers
* https://www.katacoda.com/courses/kubernetes/creating-kubernetes-yaml-definitions

## Notes

These articles are listed in the order in order you should read them. Later articles uses the K8S resources created in earlier articles.
 
* kops
    * [Cluster](docs/create-cluster.md)
    * [HA Cluster](docs/create-ha-cluster.md)
* [Create sandbox namespace](docs/create-sandbox-namespace.md)
* [Run a shell inside the cluster](docs/run-shell-inside-cluster.md)
* [Create Node application](docs/create-node-application.md)
* [Deploy Certificate Manager](docs/deploy-cert-manager.md)
* [Deploy Helm](docs/deploy-helm.md)
* Databases
    * [Deploy MySQL](docs/deploy-mysql.md)
    * [Deploy PostgreSQL](docs/deploy-postgresql.md)
    * [Deploy Redis](docs/deploy-redis.md)
* [Deploy Public Docker Registry](docs/deploy-public-docker-registry.md)
* [Deploy Nginx](docs/deploy-nginx.md)
* [Deploy Jenkins](docs/deploy-jenkins.md)
* [Update Jenkins With Cluster Credentials](docs/update-jenkins-with-cluster-credentials.md)
* [Switch Between K8S Clusters](docs/switch-between-k8s-clusters.md)

## In Progress

## Research

* https://www.serverlab.ca/tutorials/development/nodejs/containerizing-a-node-js-rest-api-for-kubernetes/ - how to handle backend secrets.
* [Deploy Harbor](docs/deploy-harbor.md)
* S3 for storage
* HTTPS for security
* Access control for isolation.
* Enable HTTPS access to Node application.
* Service Mesh
* Centralized Logging (like ELK)
* Create Java Spring Boot application.
* Create Ruby on Rails applicaiton.
* Run Python jobs.
* Run Jypiter.
* How to rollback deployments
* How to do a rolling deployment
* maria database
* pgadmin
* phpmyadmin
* prometheus
* How to promote from dev to staging to production
* kong plugin for ip restriction
* keel.sh
* codecentric/jenkins
* choerodon/nexus3
* octant.dev
* cilium.io - network security
* sealed secrets
* seq
* sonarqube
* tomcat
* k8dash
* istio
* sysdig
* apollo - deployments
* draft - from azure
* fission - serverless
* anchore - image search and scanning
* aws-iam-authenticator - for create clusters without the need for a token.
* clamav
* cluster-autoscaler
* kubemq
* quarkus
* python flask
* efs-provisioner
* elastic-stack
* elasticsearch
* grafana
* goldpinger
* kibana
* kube-hunter
* kube-ops-view
* kube-state-metrics
* kured
* locust
* Ambassador - https://www.getambassador.io/ - Easily expose, secure, and manage traffic to your Kubernetes microservices of any type
* OWASP ZAP
* https://code.visualstudio.com/docs/azure/kubernetes - k8s inside visual studio code
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
<<<<<<< Updated upstream
=======
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

kubectl krew search

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
>>>>>>> Stashed changes
