# Installing Kubernetes Using kubeadm

All work being done on a Fedora CoreOS instance created by a script. The idea is that `kubeadm init` is run and then two other instances are created to be worker nodes.

## Links

* https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/
* https://jebpages.com/2019/02/25/installing-kubeadm-on-fedora-coreos/

## Prequisite

* Ansible needs python3 so be sure to create and activate a virtual environment before following any steps below. Search for `adobo` elsewhere in the project for more information.

## Process

* Start an EC2 instance. *WARNING* - The script has several hard-coded values that you'll need to change before you run it.

```bash
./start-fcos-instance.sh
```

* Follow the on-screen instructions to SSH into the instance.

* Switch to super-user.

```bash
sudo su -
```

* Initialize kubeadm. When using a t3.medium instance, kubeadm would not recognize the instance had more than one CPU. That's why the ignore parameter is being used. Your situation might not require it.

```bash
kubeadm init --ignore-preflight-errors=NumCPU
```

* Create security groups. TBD

k8s-control-plane
    6443 / api server / all
    2379-2380 / etcd server client api / kube-api-server, etcd
    10250 / kubelet api / self, control plane
    10251 / kube-scheduler / self
    10252 / kube-controller-manager / self

k8s-workers
    10250 / kubelet api / self, control plane
    30000 - 32767 / nodeport services / all

# http://localhost:10248/healthz


# Debugging

* List of reboots.

```bash
journalctl --list-boots
```

* Journal entries since last boot.

```bash
journalctl -b
```

* Journal entries for a specific service.

```bash
systemctl status kubelet
journalctl -xeu kubelet
journalctl -u kubelet.service
```

* List all Kubernetes containers running in docker.

```bash
docker ps -a | grep kube | grep -v pause
```


* SELinux status

```bash
[root@ip-172-20-47-26 ~]# sestatus
SELinux status:                 enabled
SELinuxfs mount:                /sys/fs/selinux
SELinux root directory:         /etc/selinux
Loaded policy name:             targeted
Current mode:                   enforcing
Mode from config file:          enforcing
Policy MLS status:              enabled
Policy deny_unknown status:     allowed
Memory protection checking:     actual (secure)
Max kernel policy version:      32
```

* To view SELinux context for a file.

```bash
ls -Z <file>
```

## SELinux Denial Messages

As you find new audit rules, add them to a single .te file which then is compiled into a policy file (PP extension) and activated using semodule. When you install a PP file, it relaced previous rules from that file name. When you solve one set of audit denials, new denials will appear. Keeping adding them to the same audit-rules.te file. Eventually, the denials will stop.

* Make sure that the `audit` and `setroubleshoot` packages have been installed.

* Tail the audit log to see denial messages in real time.

```bash
tail -f /var/log/audit/audit.log | grep denied
```

* Run the following command to show rules need to be adopted to avoid the denial messages.

```bash
audit2allow -a -M foo
cat foo.te
```

* Read the `foo.te` file to validate the rule list looks correct. Then merge them into `audit-rules.te`. This is a manual step. Use the following as a basic template.

```bash
cat <<EOF > audit-rules.te
module audit-rules 1.0;
require {
  type init_t;
  type var_t;
  class file { execute execute_no_trans map open read };
}
#============= init_t ==============
allow init_t var_t:file { execute execute_no_trans map open read };
EOF
```

* Check and compile the rule set.

```bash
checkmodule -M -m -o audit-rules.mod audit-rules.te
semodule_package -o audit-rules.pp -m audit-rules.mod
```

* Apply the rule set.

```bash
semodule -i audit-rules.pp
```

* Repeat as needed until you see no more denials.

## node "ip-172-20-53-161" not found

The full errror message is

```
E0410 11:22:14.245258  341179 kubelet.go:2267] node "ip-172-20-53-161" not found
```

* `ping ip-172-20-53-161` works.
* `uname -a` responds with `ip-172-20-53-161`.
* Reset stuff
```
kubeadm reset --force
rm -rf /var/lib/kubelet

kubeadm init \
  --ignore-preflight-errors=NumCPU \
  --v=2 \
  --apiserver-advertise-address=0.0.0.0 \
  --pod-network-cidr=10.244.0.0/16

systemctl status kubelet

k8s_etcd_etcd-ip-172-20-53-161_kube-system_415459362ede07b90c022a9cc4a2bc8b_18

systemctl stop kubelet.service
systemctl status kubelet.service

/opt/bin/kubelet \
  --bootstrap-kubeconfig=/etc/kubernetes/bootstrap-kubelet.conf \
  --kubeconfig=/etc/kubernetes/kubelet.conf \
  --config=/var/lib/kubelet/config.yaml \
  --cgroup-driver=systemd \
  --network-plugin=cni \
  --pod-infra-container-image=k8s.gcr.io/pause:3.2

        