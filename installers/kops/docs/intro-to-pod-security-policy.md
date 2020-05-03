# Introduction To Pod Security Policy (PSP)

## Links

* https://starkandwayne.com/blog/protecting-yourself-with-pod-security-policies/

## Questions

All of the steps in this document work. However, some mysteries remain.

* Given a k8s cluster created by someone else, how can kubectl be configured to access it? 
* How does that access by limited by service account instead of having admin rights?
* How do we create actual user logins for the cluster instead of using service accounts which are meant for machine-to-machine use and not human-to-machine? See https://www.tremolosecurity.com/kubernetes/ for more information.
* Can kops add the adminission controllers when the cluster is created?

## Description

A [Pod Security Policy](https://kubernetes.io/docs/concepts/policy/pod-security-policy/) is a *cluster-level* resource that controls security sensitive aspects of the pod specification. The PodSecurityPolicy objects define a set of conditions that a pod must run with in order to be accepted into the system, as well as defaults for the related fields.

Pod security policy controls are implemented as an optional (but recommended) admission controller. PodSecurityPolicies are enforced by enabling the admission controller, but doing so without authorizing any policies will prevent any pods from being created in the cluster.

Note that a pod's security context - while an important topic - is different than a pod security policy. For information about setting a pod's security context, see https://kubernetes.io/docs/tasks/configure-pod-container/security-context/.

In addition to restricting pod creation and update, pod security policies can also be used to provide default values for many of the fields that it controls. This aspect of PSP is beyond the scope of this article.

In our typhoon-based cluster, the `default:restricted` cluser role binding applies the `psp:restricted` role to all authenticated system users and to all service accounts. And that role has no rules so by default, users and service accounts can do nothing. This is not part of pod security policies but it is important to know.

## Links

* Primary
  * https://kubernetes.io/docs/concepts/policy/pod-security-policy/
  * https://www.tremolosecurity.com/kubernetes-security-myths-debunked/
* Secondary
  * https://docs.bitnami.com/kubernetes/how-to/secure-kubernetes-cluster-psp/

* https://github.com/grafeas/kritis - Deploy-time Policy Enforcer for Kubernetes applications. Binary Authorization allows stakeholders to ensure that deployed software artifacts have been prepared according to organization’s standards.

## Is Your Cluster Vulnerable?

* Based on https://starkandwayne.com/blog/protecting-yourself-with-pod-security-policies/

Before getting into details, let's see if your cluster is vulnerable to a simple hack. The following set of commands creates a `kubectl` plugin which tries to get `root` on a cluster node. If the pod runs, you'll have full superuser permissions on a worker node.

```bash
cat <<EOF > $HOME/bin/kubectl-r00t.sh
#!/bin/bash
exec kubectl run r00t -it --rm \
  --restart=Never \
  --image nah r00t \
  --overrides '{"spec":{"hostPID": true, "containers":[{"name":"x","image":"alpine","command":["nsenter","--mount=/proc/1/ns/mnt","--","/bin/bash"],"stdin": true,"tty":true,"securityContext":{"privileged":true}}]}}' "$@"
EOF
chmod +x $HOME/bin/kubectl-r00t.sh
$HOME/bin/kubectl r00t
# do root stuff.
exit
^C
```

If that worked, it worked because the pod

* was privileged
* was in the hostPID namespace
* ran as the root user (UID/GID of 0/0)
* ran with stdin attached, and a controlling terminal

On a typhoon-based cluster that followed the creation procedure in the this project, this hack is expected to fail. You might see an error like the following. It has been edited for clarity.

```
pods "r00t" is forbidden: unable to validate against any pod security policy: 
  Invalid value: true: Host PID is not allowed to be used 
  Invalid value: true: Privileged containers are not allowed
```

## Adding Adminmission Controllers

## kops-based cluster

* Edit the cluster.

```bash
kops edit cluster
```

* Add the following lines to the yaml file. Make sure to get the indenting correct. Don't duplicate the `spec` line. That one is just to show the proper indenting.

```yaml
spec:
  kubeAPIServer:
    admissionControl:
      - NamespaceLifecycle
      - LimitRanger
      - ServiceAccount
      - PersistentVolumeLabel
      - DefaultStorageClass
      - ResourceQuota
      - PodSecurityPolicy
      - DefaultTolerationSeconds
```

* Update the cluster. Run the command without the `--yes` parameter to see what will change.

```bash
kops update cluster --yes
```

* Perform a rolling update. This will drain and restart nodes. Do the restart during a non-critical time for your cluster. For my small cluster, this took less than 10 minutes.

```bash
kops rolling-update cluster --yes
```

## typhoon-based cluster

Already done.

## Limit Permisions For Unprivleged User

In order to demonstrate PSPs, you need to create service accounts with different permissions. In this section you'll create two users, one will be able to create any pod and one which will be limited. During development, the limited service accont should be used.

* Create a namespace for experimentation. Create a service account. Then create some aliases to reduce typing.

```bash
kubectl create namespace psp-ns
kubectl --namespace psp-ns create serviceaccount psp-sa

alias kadmin='kubectl --namespace psp-ns'
alias kuser='kubectl --namespace psp-ns --as=system:serviceaccount:psp-ns:psp-sa'
```

* Prove that the newly created service account has no permissions. You'll see the message "pods is forbidden".

```bash
kuser get pods
```

* Create a role and a role binding to allow working with pods. Keep in mind that roles serve a different purpose that pod security polices. For example, with this role the service account can't list deployments or even service accounts so it can't see itself. Remember that these are namespace-specific.

```bash
kubectl apply -f - <<EOF
---
kind: Role
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: psp-sa-role
  namespace: psp-ns
rules:
  - apiGroups: ['']
    resources: [pods]
    verbs:     [get, list, watch, create, update, patch, delete]
---
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: psp-sa-rolebinding
  namespace: psp-ns
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind:     Role
  name:     psp-sa-role
subjects:
  - kind: ServiceAccount
    name: psp-sa
EOF
```

* Prove that the newly created service account has no permissions. You'll see the message "pods is forbidden".

```bash
kuser get pods
```

* Before moving on, review the existing pod security polices. Remember, these are cluster-wide. you'll see at least `privleged` and `restricted`.

```bash
$HOME/bin/kubectl get PodSecurityPolicies
```

* You can also look at cluster roles associated with pod security policies. Note that starting cluster roles with `psp:` is a naming convention. Please follow it to enable commands like this.

```bash
$HOME/bin/kubectl get ClusterRoles | grep "^psp"
```

* Also, check roles in the namespace.

```bash
$HOME/bin/kubectl --namespace psp-ns get roles
```

* `kuser` can pods.

```bash
kuser get pods
```

* However, `kuser` can't start a pod because it is not associated with a pod security policy yet.

```bash
kuser apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: unable-to-launch
spec:
  containers:
  - name: $POD_NAME
    image: centos
EOF
```

* Update the `psp-sa-role` 

* The follow may not be needed in the 
psp-sa-allow-restricted-psp-role role.

```
- apiGroups:      [extensions]
  resources:      [podsecuritypolicies]
  verbs:          [use]
  resourceNames:  [restricted]
```

```bash
kubectl apply -f - <<EOF
---
kind: Role
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: psp-sa-allow-restricted-psp-role
  namespace: psp-ns
rules:
- apiGroups:      [policy]
  resources:      [podsecuritypolicies]
  resourceNames:  [restricted]
  verbs:          [use]
---
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: psp-sa-allow-restricted-psp-rolebinding
  namespace: psp-ns
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind:     Role
  name:     psp-sa-allow-restricted-psp-role
subjects:
  - kind: ServiceAccount
    name: psp-sa
EOF
```

* With the new role and role binding, `kuser` can now start a pod. Notice that the user and group need to be specified. If not you will see a current state of "waiting: container has runAsNonRoot and image will run as root". The pod starts but you can't exec into it.

```bash
kuser apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: able-to-launch
spec:
  containers:
  - name: able-to-launch
    image: centos
    command: ["/bin/bash"]
    args: ["-c", "while true; do date; sleep 5; done"]
    securityContext:
      runAsUser: 1000
      runAsGroup: 1000
  dnsPolicy: Default
  restartPolicy: Never
EOF

kuser get pod -w
kuser delete pod able-to-launch
```

* Trying to create a privleged pod fails. You should see the error "Privileged containers are not allowed".

```bash
kuser apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: i-have-privilege
spec:
  containers:
  - name: i-have-privilege
    image: centos
    command: ["/bin/bash"]
    args: ["-c", "while true; do date; sleep 5; done"]
    securityContext:
      runAsUser: 1000
      runAsGroup: 1000
      privileged: true
  dnsPolicy: Default
  restartPolicy: Never
EOF

## Allowing EXEC into a container

After starting the `able-to-launch` pod from earlier, trying to use `exec` fails.

```bash
kuser exec able-to-launch -- /bin/bash
kuser delete pod able-to-launch

```

```bash
kubectl apply -f - <<EOF
---
kind: Role
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: psp-sa-allow-pod-exec-psp-role
  namespace: psp-ns
rules:
- apiGroups:      [""]
  resources:      [pods/exec]
  verbs:          [create]
---
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: psp-sa-allow-pod-exec-psp-rolebinding
  namespace: psp-ns
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind:     Role
  name:     psp-sa-allow-pod-exec-psp-role
subjects:
  - kind: ServiceAccount
    name: psp-sa
EOF
```



## Compliance Check

### Limit Access To cluster-admin Role

You can explore the cluster roles and roles using `kubectl get clusterrolebinding` or `kubectl get rolebinding –all-namespaces`. Check who is granted the special `cluster-admin` role.

### Remove automountServiceAccountToken

Most applications don’t need to access the API at all; `automountServiceAccountToken` can be set to “false” in the `spec` section of a pod manifest.

### Remove default Namespace

If you are using purpose-specific namespaces or use namespaces for process isolation, then removing the `default` namespace will ensure that all work is namespace-aware.

### kube-psp-advisor

* https://github.com/sysdiglabs/kube-psp-advisor

Sysdig Labs has created a tool called `kube-psp-advisor` which lets you see see the de-facto PSP applicable to a namespace. This tools lets you learn about a namespace and what it might need for a PSP.

## Policy Examples

This section provides policy examples that need to be tailored as needed.

* No Host Port Access

This policy is good for any kind of scheduled task. 

```yaml
spec:
  hostPorts:
  - min: 0
    max: 0
```

* Restricted Host Port Access

This policy is good idea for any server process. The example below would work for MySQL. The same restriction can be handled in other ways (such as security groups) but using a k8s policy provides pod-level flexibility using a vendor-neutral technique.

```yaml
spec:
  hostPorts:
  - min: 3306
    max: 3306
```

# Cleanup

```
$HOME/bin/kubectl delete namespace psp-ns
```

# Troubleshooting

NOTE: Ignore the warning: "resource 'podsecuritypolicies' is not namespace scoped in group 'policy'"
