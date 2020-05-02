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

### Goals

The goal of this document is two create two policies. One for administrators and another for non-privileged users. It will take a few steps to get there.

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
kubectl r00t
# do root stuff.
exit
^C
kubernetes delete pod r00t
```

If that worked, it worked because the pod

* was privileged
* was in the hostPID namespace
* ran as the root user (UID/GID of 0/0)
* ran with stdin attached, and a controlling terminal

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

TBD

## PSP List

You can view a list of all PSPs using the following command.

```bash
kubectl get podsecuritypolicies
```

There might be a created policy called `kube-system` that has the following manifest:

```yaml
apiVersion: policy/v1beta1
kind: PodSecurityPolicy
metadata:
  annotations:
    k8s-addon: podsecuritypolicy.addons.k8s.io
  name: kube-system
spec:
  allowPrivilegeEscalation: true
  allowedCapabilities:
  - '*'
  fsGroup:
    rule: RunAsAny
  hostIPC: true
  hostNetwork: true
  hostPID: true
  hostPorts:
  - max: 65536
    min: 1  
  privileged: true
  runAsUser:
    rule: RunAsAny
  seLinux:
    rule: RunAsAny
  supplementalGroups:
    rule: RunAsAny
  volumes:
  - '*'
```

## Limit Permisions For Unprivleged User

In order to demonstrate PSPs, you need to create service accounts with different permissions. In this section you'll create two users, one will be able to create any pod and one which will be limited. During a standard deployment, the limited service accont should be used.

Notice that two aliases are also created to allow for easy testing of the PSP. The `kadmin` command is a convenience to avoid adding the namespace.

* As always, create a namespace for experimentation.

```bash
kubectl create namespace psp-ns
```

* Now create a service account.

```bash
kubectl --namespace psp-ns create serviceaccount psp-sa
```

kubectl --namespace psp-ns create rolebinding \
  fake-editor \
  --clusterrole=edit \
  --serviceaccount=psp-ns:psp-sa

kubectl create -f https://git.io/fNhJX -n psp-ns \
  --as-group=system:authenticated \
  --as=system:serviceaccount:psp-ns:psp-sa

* Here are some alias to make life easier in later steps. A *normal* user uses a service account (psp-sa) but the admin user does not. Since no service account is used, it has all of the permissions.

```bash
alias kadmin='kubectl --namespace psp-ns'
alias kuser='kubectl --namespace psp-ns --as=system:serviceaccount:psp-ns:psp-sa'
```

* Create a role and a role binding to allow the service account to deploy pods. Keep in mind that roles serve a different purpose that pod security polices. For example, with this role the service account can't list deployments or even service accounts so it can't see itself.

```bash
kubectl apply -f - <<EOF
---
kind: Role
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: psp-sa
  namespace: psp-ns
rules:
  - apiGroups: ['']
    resources: [pods]
    verbs:     [get, list, watch, create, update, patch, delete]

---
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: psp-sa
  namespace: psp-ns
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind:     Role
  name:     psp-sa
subjects:
  - kind: ServiceAccount
    name: psp-sa
EOF
```

* Create a privleged pod security policy.

```bash
kubectl apply -f - <<EOF
---
apiVersion: policy/v1beta1
kind: PodSecurityPolicy
metadata:
  name: privileged
spec:
  privileged: true
  allowPrivilegeEscalation: true
  allowedCapabilities: ['*']
  volumes: ['*']
  hostNetwork: true
  hostIPC:     true
  hostPID:     true
  hostPorts: [{ min: 0, max: 65535 }]
  runAsUser:          { rule: RunAsAny }
  seLinux:            { rule: RunAsAny }
  supplementalGroups: { rule: RunAsAny }
  fsGroup:            { rule: RunAsAny }
EOF
```

* Create a restricted security policy.

```bash
kubectl apply -f - <<EOF
---
apiVersion: policy/v1beta1
kind: PodSecurityPolicy
metadata:
  name: restricted
spec:
  privileged:               false
  allowPrivilegeEscalation: false
  requiredDropCapabilities: [ALL]
  readOnlyRootFilesystem:   false

  hostNetwork: false
  hostIPC:     false
  hostPID:     false

  runAsUser:
    # Require the container to run without root privileges.
    rule: MustRunAsNonRoot

  seLinux:
    # Assume nodes are using AppArmor rather than SELinux.
    rule: RunAsAny

  supplementalGroups:
    rule: MustRunAs
    ranges: [{ min: 1, max: 65535 }]

  fsGroup:
    rule: MustRunAs
    ranges: [{ min: 1, max: 65535 }]

  # Allow core volume types.
  volumes:
    - configMap
    - emptyDir
    - projected
    - secret
    - downwardAPI
    - persistentVolumeClaim
EOF
```

* List the pod security polices in place. Since we have no cluster roles allowing their use, they are inert and not protecting anything.

```bash
kubectl get psp
```

* Create a cluster role that can list and get all security policies but only use the restricted policy.

```bash
kubectl delete ClusterRole default-psp

kubectl apply -f - <<EOF
---
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: default-psp
rules:
  - apiGroups:     [policy]
    resources:     [podsecuritypolicies]
    resourceNames: []
    verbs:         [list, get]

  - apiGroups:     [policy]
    resources:     [podsecuritypolicies]
    resourceNames: [restricted]
    verbs:         [use]
EOF
```


* Now bind the cluster role to all users and all service accounts.

```bash
kubectl apply -f - <<EOF
---
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: default-psp
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind:     ClusterRole
  name:     default-psp
subjects:
  - apiGroup: rbac.authorization.k8s.io
    kind:     Group
    name:     system:authenticated # All authenticated users
  - apiGroup: rbac.authorization.k8s.io
    kind:     Group
    name:     system:serviceaccounts
EOF
```

* As the normal user, list pods.

```bash
kuser get pods
```

* Using `can-i` explore what permissions exist.

```bash
kuser auth can-i create pods
kuser auth can-i use psp/privileged
kuser auth can-i use psp/restricted

kadmin auth can-i create pods
kadmin auth can-i use psp/privileged
kadmin auth can-i use psp/restricted
```

NOTE: Ignore the warning: "resource 'podsecuritypolicies' is not namespace scoped in group 'policy'"

* Try the root hack as the normal user. It may take a few seconds, but you'll see an error message.

```bash
kubectl r00t --namespace psp-ns --as=system:serviceaccount:psp-ns:psp-sa
```

## Show EXEC Does Not Work

The following sequence of steps shows that the `kubectl exec` command won't work for the non-privledged user.

```bash
POD_NAME="bash-shell-$(uuid | cut -b-5)"

kuser apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: $POD_NAME
  namespace: psp-ns
spec:
  containers:
  - name: $POD_NAME
    image: centos
    command: ["/bin/bash"]
    args: ["-c", "while true; do date; sleep 5; done"]
  dnsPolicy: Default
  hostNetwork: true
  restartPolicy: Never
EOF

# Press ^C when pod is ready.
kuser get pod $POD_NAME -w

# This fails.
kuser exec -it $POD_NAME -- /bin/bash

# This works.
kadmin exec -it $POD_NAME -- /bin/bash

kuser delete pod $POD_NAME
```

--------------------------------------------------------------------
--------------------------------------------------------------------
--------------------------------------------------------------------
--------------------------------------------------------------------
--------------------------------------------------------------------
--------------------------------------------------------------------
--------------------------------------------------------------------
--------------------------------------------------------------------
--------------------------------------------------------------------
IN PROGRESS SECTION
--------------------------------------------------------------------
--------------------------------------------------------------------
--------------------------------------------------------------------
--------------------------------------------------------------------
--------------------------------------------------------------------
--------------------------------------------------------------------
--------------------------------------------------------------------


## Fail To Create a Privileged Pod

```bash
POD_NAME="bash-shell-$(uuid | cut -b-5)"

kuser apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: $POD_NAME
  namespace: psp-ns
spec:
  containers:
  - name: $POD_NAME
    image: centos
    command: ["/bin/bash"]
    args: ["-c", "while true; do date; sleep 5; done"]
    securityContext:
      privileged: true
EOF

# Press ^C when pod is ready.
kuser get pod $POD_NAME -w

# This fails.
kuser exec -it $POD_NAME -- /bin/bash

# This works.
kadmin exec -it $POD_NAME -- /bin/bash

kuser delete pod $POD_NAME
```

You should see the error "Privileged containers are not allowed".


--------------------------------------------------------------------
--------------------------------------------------------------------
--------------------------------------------------------------------
--------------------------------------------------------------------
--------------------------------------------------------------------
--------------------------------------------------------------------
--------------------------------------------------------------------
--------------------------------------------------------------------
--------------------------------------------------------------------
--------------------------------------------------------------------
--------------------------------------------------------------------
--------------------------------------------------------------------
--------------------------------------------------------------------







## Fail To Create an Unprivileged Deployment

In this example, you'll perform a deployment. Notice the manifest has a few more lines than a Pod manifest. Notice that this deployment uses `runAsUser` and `runAsGroup` to make sure the container does not run as root. Without those two lines, you'd see a `Error: container has runAsNonRoot and image will run as root` error.

```bash
cat <<EOF > yaml/unprivileged_deployment.yaml
apiVersion: apps/v1 
kind: Deployment 
metadata:  
    name: psp-deploy
    labels: 
      app: paused 
spec: 
  replicas: 1 
  selector: 
    matchLabels: 
      app: paused 
  template: 
    metadata: 
      labels:  
        app: paused 
    spec: 
      securityContext:
        runAsUser: 1000
        runAsGroup: 1000
      containers: 
      - name: paused 
        image: k8s.gcr.io/pause 
EOF
psp-user apply -f yaml/unprivileged_deployment.yaml
psp-user get deployment psp-deploy
psp-user delete deployment psp-deploy
```

You'll see `0/1` pods are ready. This time, look at events to find the reason.

```
psp-user get events --sort-by='.metadata.creationTimestamp'
Error creating: pods "psp-deploy-664b4c9b6-" is forbidden: unable to validate against any pod security policy: []
```

Once again, a RoleBinding is missing.

## Add the RoleBinding For Deployment and Redeploy

After creating the RoleBinding and redeploying, the pod will start.

```
psp-admin create rolebinding rb-id3 --role=psp-role --serviceaccount=psp-ns:default
psp-user apply -f yaml/unprivileged_deployment.yaml
psp-user get deployment psp-deploy
psp-user delete deployment psp-deploy
```

## Suggested Common Policy

* Enable read-only root filesystem
* Enable security profiles
* Prevent host network access
* Prevent privileged mode
* Prevent root privileges
* Whitelist read-only host path
* Whitelist volume types

```bash
cat <<EOF > yaml/restricted-psp.yaml
apiVersion: policy/v1beta1
kind: PodSecurityPolicy
metadata:
  name: restricted
  annotations:
    seccomp.security.alpha.kubernetes.io/allowedProfileNames: 'docker/default,runtime/default'
    apparmor.security.beta.kubernetes.io/allowedProfileNames: 'runtime/default'
    seccomp.security.alpha.kubernetes.io/defaultProfileName:  'runtime/default'
    apparmor.security.beta.kubernetes.io/defaultProfileName:  'runtime/default'
spec:
  # Restrict pods to just a /pod directory and ensure that it is read-only.
  allowedHostPaths:
    - pathPrefix: /pod
      readOnly: true 
  allowPrivilegeEscalation: false
  fsGroup:
    rule: 'MustRunAs'
    ranges:
      # Forbid adding the root group.
      - min: 1
        max: 65535
  hostNetwork: false
  hostIPC: false
  hostPID: false
  privileged: false
  readOnlyRootFilesystem: true
  # This is redundant with non-root + disallow privilege escalation,
  # but we can provide it for defense in depth.
  requiredDropCapabilities:
    - ALL
  # Allow core volume types.
  runAsUser:
    # Require the container to run without root privileges.
    rule: 'MustRunAsNonRoot'
  seLinux:
    # This policy assumes the nodes are using AppArmor rather than SELinux.
    rule: 'RunAsAny'
  supplementalGroups:
    rule: 'MustRunAs'
    ranges:
      # Forbid adding the root group.
      - min: 1
        max: 65535
  volumes:
    - 'configMap'
    - 'downwardAPI'
    - 'emptyDir'
    # Assume that persistentVolumes set up by the cluster admin are safe to use.
    - 'persistentVolumeClaim'
    - 'projected'
    - 'secret'

EOF
kubectl apply -f yaml/restricted-psp.yaml
```

## Security Reminders

Because it is always good to review propery security.

* After you install your packages, switch to an unprivileged user
* Don’t write data to your pod unless its setup with an emptyVolume mount
* Cluster-wide permissions should generally be avoided in favor of namespace-specific permissions.

## Compliance Check

### Limit Access To cluster-admin Role

You can explore the cluster roles and roles using `kubectl get clusterrolebinding` or `kubectl get rolebinding –all-namespaces`. Check who is granted the special `cluster-admin` role.

### Remove automountServiceAccountToken

Most applications don’t need to access the API at all; `automountServiceAccountToken` can be set to “false” in the `spec` section of a pod manifest.

### Remove default Namespace

If you are using purpose-specific namespace or use namespaces for process isolation, then removing the `default` namespace will ensure that all work is namespace-aware.

### kube-psp-advisor

Use this tool from Sysdig Labs to check for namespaces with LAX policies.

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

## sysdiglabs/kube-psp-advisor

* https://github.com/sysdiglabs/kube-psp-advisor

Sysdig Labs has created a tool called `kube-psp-advisor` which lets you see see the de-facto PSP applicable to a namespace. This tools lets you learn about a namespace and what it might need for a PSP. For example, while there is no PSP associated with the resources in the `kubernetes-dashboard` namespace, using the following command:

```
kubectl advise-psp inspect --namespace=kubernetes-dashboard
```

shows a PSP like the following:

```yaml
apiVersion: policy/v1beta1
kind: PodSecurityPolicy
metadata:
  creationTimestamp: null
  name: pod-security-policy-kubernetes-dashboard-20200401152221
spec:
  allowPrivilegeEscalation: false
  fsGroup:
    rule: RunAsAny
  readOnlyRootFilesystem: true
  runAsGroup:
    ranges:
    - max: 2001
      min: 2001
    rule: MustRunAs
  runAsUser:
    ranges:
    - max: 1001
      min: 1001
    rule: MustRunAs
  seLinux:
    rule: RunAsAny
  supplementalGroups:
    rule: RunAsAny
  volumes:
  - emptyDir
  - secret
```


# Cleanup

```
$HOME/bin/kubectl delete namespace psp-ns
```