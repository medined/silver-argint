# kubeadm

Kubeadm is a toolkit for bootstrapping a best-practises Kubernetes cluster on existing 
infrastructure. Kubeadm cannot provision your infrastructure which is one of the main 
differences to kops. Another differentiator is that Kubeadm can be used not only as 
an installer but also as a building block.

Kubeadm sets up a minimal viable cluster. It is designed to have all the components 
you need in one place in one cluster regardless of where you are running them.

## Fedora CoreOS

Fedora CoreOS (FCOS) is an automatically updating, minimal, monolithic, container-focused operating system, designed for clusters but also operable standalone, optimized for Kubernetes but also great without it. It aims to combine the best of both CoreOS Container Linux and Fedora Atomic Host, integrating technology like Ignition from Container Linux with rpm-ostree and SELinux hardening from Project Atomic. Its goal is to provide the best container host to run containerized workloads securely and at scale.

Fedora CoreOS is an open source project associated with the Fedora Project. We are aiming for high compatibility with existing Container Linux configuration and user experience, and we expect to provide documentation and tooling to help migrate from Container Linux to Fedora CoreOS.

Fedora CoreOS (FCOS) has no install-time configuration. Every FCOS system begins with a generic disk image. For each deployment mechanism (cloud VM, local VM, bare metal), configuration can be supplied at first boot. FCOS reads and applies the configuration file with Ignition. For cloud deployments, Ignition gathers the configuration via the cloud’s user-data mechanism.

## TODO

* Add role 'k8s-nodes' to EC2 instance.

## Amazon SSM Agent

Follow instructions at https://github.com/aws/amazon-ssm-agent to compile the SSM agent. This is needed in order to copy the binaries over to the EC2 instances.

However, the hard-coded path to ssm-document-worker, ssm-session-worker, and ssm-session-logger in constants-unix.go should be changed to use /usr/local/bin.

Also note that I needed to run `sudo make build-linux`.

Follow instructions at https://console.aws.amazon.com/systems-manager/quick-setup?region=us-east-1 to setup SSM. 

Create an IAM Role called 'k8s-nodes' with EC2 as the trusted entity. Add the `AmazonSSMFullAccess` and `AmazonSSMMangedInstanceCore` policies.

Install the SSM Plugin so that you can use the cli from your workstation.

See https://medium.com/levops/how-to-work-with-aws-simple-system-manager-on-coreos-4741853dfd50 for more information.

## Amazon CloudWatch Agent

The Amazon CloudWatch agent is used to send logs from the FCOS intance to CloudWatch. This is done using a container. An ansible playbook handles all of the configuration.

The logs will be in CloudWatch Logs under the `audit` log group under the instance id.

The following query can be used on the Logs > Insights page to see the last 20 logins.

```
fields @timestamp, @message
| sort @timestamp desc
| filter @message like /USER_LOGIN/
| limit 20
```

You can turn log events into metrics by creating a Metric Filter. Then alert on the metric.

## Configure Python Environment

This project uses python. So python needs to be installed. Use python 3, please. Installing python and pip are beyond the scope of this document.

```bash
pip install --user pipenv
python3 -m venv venv
echo "venv" >> .gitignore
source venv/bin/activate
pip install wheel
pip install -r requirements.txt
```


### Words of Caution

The Fedora CoreOS is very dynamic and anything is this document might change.

## Process

* Provision several Linux machines with a UNIX flavour
* Install kubeadm
* Make one of your machines the master (or the control plane)
* Install a pod networking layer like Weave Net
* Join the other nodes to the master

## Links

* https://www.cloudtechnologyexperts.com/kubeadm-on-aws/
* https://github.com/graykode/aws-kubeadm-terraform
* https://blog.scottlowe.org/2020/02/18/setting-up-k8s-on-aws-kubeadm-manual-certificate-distribution/
* https://revelry.co/kubeadm-aws/ - A Simple Leader Election Solution for Kubeadm in an AWS Auto Scaling Group
* https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/kubeadm-certs/
* https://support.embotics.com/support/solutions/articles/8000069019-deploying-a-kubernetes-cluster-on-aws-through-kubeadm


