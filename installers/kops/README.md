# Kops

This project documents my exploration into [kubernets](https://kubernetes.io/). Each goal shown below is fairly simple and intended to be short and declarative. You'll need to read the orginal source material by following the links in each article to learn context.

## TL;DR

See the [order of scripts](docs/00-order-of-scripts.md) section if you just need to know what scripts can be fun and in what order.

## Notes

These articles are listed in the order in order you should read them. Later articles uses the K8S resources created in earlier articles.

* System Administration
    * [Introduction To dig, the DNS Lookup Utility](docs/intro-to-dig.md)
* [Gentle Intro To Kubernetes](docs/gentle_introduction_to_kubernetes.md)
* [Curated Videos From Cloud Native Computing Foundation](docs/currated_video_list.md)
* kops
    * [Cluster](docs/create-cluster.md)
    * [HA Cluster](docs/create-ha-cluster.md) - three masters and two nodes.
    * [Add/Remove a Node](docs/kops-add-node-to-cluster.md)
    * [Using Spot Instances](docs/using-spot-instances-as-nodes.md)
* [Deploy Dashboard](docs/deploy-dashboard.md) - insight into k8s resources.
* [Create sandbox namespace](docs/create-sandbox-namespace.md)
* [Run a shell inside the cluster](docs/run-shell-inside-cluster.md)
* [Create Node application](docs/create-nodejs-application.md)
* Certificate Manager
    * [Deploy Certificate Manager](docs/deploy-cert-manager.md)
    * TBD - [Add HTTPS To An Applicaton](docs/add_https_to_an_application.md)
* [Deploy Helm](docs/deploy-helm.md) - a package manager for k8s.
* See https://krew.sigs.k8s.io/ to learn about a plugin manager for kubectl
* See https://github.com/ishantanu/awesome-kubectl-plugins to read about kubectl plugins.
* Databases
    * [Deploy MySQL](docs/deploy-mysql.md)
    * [Deploy PostgreSQL](docs/deploy-postgresql.md)
    * [Deploy Redis](docs/deploy-redis.md)
* [Deploy Public Docker Registry](docs/deploy-public-docker-registry.md)
* [Deploy Nginx](docs/deploy-nginx.md)
* [Deploy Jenkins](docs/deploy-jenkins.md)
* [Update Jenkins With Cluster Credentials](docs/update-jenkins-with-cluster-credentials.md)
* [Switch Between K8S Clusters](docs/switch-between-k8s-clusters.md)
* Security
    * [Deploy Service (application) With HTTPS](docs/deploy-service-with-https.md)
    * [Introduction To Pod Security Policy](docs/intro-to-pod-security-policy.md)
    * [Introduction To Kernel Isolation](docs/intro-to-kernel-isolation.md)
* Testing
    * Security
        * [OWASP-ZAP](docs/intro-to-owasp-zap.md)
* DistroLess
    * [Introduction To DistroLess](docs/intro-to-distrless.md)
* [Troubleshooting](docs/troubleshooting.md)

## Research

See [Research](../../README-research.md)
