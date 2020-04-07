# Installing Kubernetes Using kubeadm

## Links

* https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/
* https://jebpages.com/2019/02/25/installing-kubeadm-on-fedora-coreos/

## Prequisite

* Ansible needs python3 so be sure to create and activate a virtual environment before following any steps below. Search for `adobo` elsewhere in the project for more information.

## Creating an Fedora CoreOS Instance

The intention is that the instance will be used when creating the cluser.

```bash
./start-fcos-instance.sh
```

*WARNING* - The script has several hard-coded values that you'll need to change before you run it.
