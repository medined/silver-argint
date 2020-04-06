# Introduction To Pod Security Policy (PSP)

## Questions

All of the steps in this document work. However, some mysteries remain.

* Given a k8s cluster created by someone else, how can kubectl be configured to access it? 
* How does that access by limited by service account instead of having admin rights?
* What is the difference in the following two statements. Why does the second statement allow Deployments while the first allows Pod creation?
```bash
psp-admin create rolebinding rb-id2 --role=psp-role --serviceaccount=psp-ns:psp-sa
psp-admin create rolebinding rb-id3 --role=psp-role --serviceaccount=psp-ns:default
```
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

## Adding Adminission Controllers to a kops-based cluster

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

## PSP List

You can view a list of all PSPs using the following command.

```bash
kubectl get podsecuritypolicies
```

There should be an already created policy called `kube-system` that has the following manifest:

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

## Create psp-admin and psp-user service accounts

In order to demonstrate PSPs, you need to create service accounts with different permissions. In this section you'll create two users, one will be able to create any pod and one which will be limited. During a standard deployment, the limited service accont should be used.

Notice that two aliases are also created to allow for easy testing of the PSP.

```bash
kubectl create namespace psp-ns
kubectl create serviceaccount -n psp-ns psp-sa
kubectl create rolebinding -n psp-ns rb-id --clusterrole=edit --serviceaccount=psp-ns:psp-sa
alias psp-admin='kubectl -n psp-ns'
alias psp-user='kubectl --as=system:serviceaccount:psp-ns:psp-sa -n psp-ns'
```

A *normal* uses a service account (psp-sa) but the admin user does not. Since no service account is used, it has all of the permissions.

## PSP Manifest

```bash
cat <<EOF > yaml/restricted.yaml
apiVersion: policy/v1beta1
kind: PodSecurityPolicy
metadata:
  name: restricted
spec:
  privileged: false
  runAsUser:
    rule: MustRunAsNonRoot
  seLinux:
    rule: RunAsAny
  fsGroup:
    rule: RunAsAny
  supplementalGroups:
    rule: RunAsAny
  volumes:
  - '*'
EOF
kubectl apply -f yaml/restricted.yaml
```

## Create a pod that should fail

```bash
cat <<EOF > yaml/pod-pause.yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-pause
spec:
  containers:
  - name: pause
    image: k8s.gcr.io/pause
EOF
psp-user create -f yaml/pod-pause.yaml
```

With luck, you'll see the following error:

```bash
Error from server (Forbidden): error when creating "yaml/pod-pause.yaml": pods "pod-pause" is forbidden: unable to validate against any pod security policy: []
```

Use the `auth can-i` sub-command to see the error. The `no` means their is no authorization.

```bash
psp-user auth can-i use podsecuritypolicy/psp-policy
Warning: resource 'podsecuritypolicies' is not namespace scoped in group 'policy'
no
```

## Use RoleBinding To Give psp-user The Policy

The value of the `resourceNames` field is the name of the PSP created previously. Notice that the service account is references as `psp-ns:psp-sa` which is a combination of a namespace and a service account.

```bash
psp-admin apply -f - <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: psp-role
rules:
  - apiGroups: ['policy']
    resources: ['podsecuritypolicies']
    verbs: ['use']
    resourceNames: ['restricted']
EOF

psp-admin create rolebinding rb-id2 --role=psp-role --serviceaccount=psp-ns:psp-sa
```

## Sucessfully Start Pod As psp-user

```bash
psp-user apply -f yaml/pod-pause.yaml
psp-user get pods
psp-user delete po/pod-pause
```

Remember before the role was bound, creating the pod failed. Now, the container will start but pause. If you look at the logs before deletion, you'll see this:

```bash
$ psp-admin logs pod-pause
Error from server (BadRequest): container "pause" in pod "pod-pause" is waiting to start: CreateContainerConfigError
```

*NOTE*: You might see internet articles that use "psp-admin ... --verb=use" instead of the YAML used above. That command won't work. See https://github.com/kubernetes/kubernetes/issues/85314 for more information.

## Fail To Create a Privileged Pod

```bash
cat <<EOF > yaml/privileged_pod.yaml
apiVersion: v1 
kind: Pod 
metadata:   
    name: privileged 
spec:   
    containers:
    - name:  pause
      image: k8s.gcr.io/pause
      securityContext:
        privileged: true
EOF
psp-user apply -f yaml/privileged_pod.yaml
```

You should see the error "Privileged containers are not allowed".

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