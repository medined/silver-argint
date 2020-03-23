# Introduction To Pod Security Policy

## NOTE

* Create a (user) service account to start a pod to compare with the admin role.
* YES - `kubectl auth can-i use psp/privileged`
* NO - `kubectl auth can-i use psp/privileged --as-group=system:authenticated --as=any-user`
* YES - `kubectl auth can-i use psp/restricted --as-group=system:authenticated --as=any-user`


## Description

A Pod Security Policy is a *cluster-level* resource that controls security sensitive aspects of the pod specification. The PodSecurityPolicy objects define a set of conditions that a pod must run with in order to be accepted into the system, as well as defaults for the related fields.

Pod security policy control is implemented as an optional (but recommended) admission controller. PodSecurityPolicies are enforced by enabling the admission controller, but doing so without authorizing any policies will prevent any pods from being created in the cluster.

* Create pod security policies.
* Enable the PodSecurityPolicy admission controller.
* Create ClusterRole granting `use` access to the privileged PodSecurityPolicy.
* Create ClusterRoleBinding binding server accounts to the ClusterRole.

### Kube-PSP-Advisor

Kube-PSP-Advisor is a tool that makes it easier to create K8s Pod Security Policies (PSPs) from either a live K8s environment or from a single. yaml file containing a pod specification (deployment, daemon set, pod, etc.).

## Pod Security Management

* View Policies.

```
kubectl get podsecuritypolicies
```

### Goals

The goal of this document is two create two policies. One for administrators and another for non-privileged users.

## Links

* https://play.vidyard.com/vEfDKAhmcx1NAz4a8az1zJ
* https://kubernetes.io/docs/concepts/policy/pod-security-policy/
* https://containerjournal.com/topics/container-security/establishing-a-kubernetes-pod-security-policy/
* https://cloud.google.com/kubernetes-engine/docs/how-to/pod-security-policies
* https://resources.whitesourcesoftware.com/blog-whitesource/kubernetes-pod-security-policy
* Rancher Documentation
  * https://rancher.com/blog/2020/pod-security-policies-part-1
  * https://rancher.com/blog/2020/pod-security-policies-part-2/
* https://docs.docker.com/ee/ucp/kubernetes/pod-security-policies/
* https://medium.com/coryodaniel/kubernetes-assigning-pod-security-policies-with-rbac-2ad2e847c754

## Examples

Read https://kubernetes.io/docs/concepts/policy/pod-security-policy/ and follow the examples.

```bash
NAMESPACE=sandbox

cat <<EOF > yaml/restricted-psp.yaml
apiVersion: policy/v1beta1
kind: PodSecurityPolicy
metadata:
  name: restricted
  namespace: $NAMESPACE
  annotations:
    seccomp.security.alpha.kubernetes.io/allowedProfileNames: 'docker/default,runtime/default'
    apparmor.security.beta.kubernetes.io/allowedProfileNames: 'runtime/default'
    seccomp.security.alpha.kubernetes.io/defaultProfileName:  'runtime/default'
    apparmor.security.beta.kubernetes.io/defaultProfileName:  'runtime/default'
spec:
  privileged: false
  # Required to prevent escalations to root.
  allowPrivilegeEscalation: false
  # This is redundant with non-root + disallow privilege escalation,
  # but we can provide it for defense in depth.
  requiredDropCapabilities:
    - ALL
  # Allow core volume types.
  volumes:
    - 'configMap'
    - 'emptyDir'
    - 'projected'
    - 'secret'
    - 'downwardAPI'
    # Assume that persistentVolumes set up by the cluster admin are safe to use.
    - 'persistentVolumeClaim'
  hostNetwork: false
  hostIPC: false
  hostPID: false
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
  fsGroup:
    rule: 'MustRunAs'
    ranges:
      # Forbid adding the root group.
      - min: 1
        max: 65535
  readOnlyRootFilesystem: false
EOF
kubectl apply -f yaml/restricted-psp.yaml
```
 - 
Compliance - runAsUser (1000) and runAsGroup (1000) so that container is not run as root. Also values must not be zero (i.e. root).

spec:
  securityContext:
    runAsUser: 1000
    runAsGroup: 1000
  containers:
  - securityContext:
      allowPrivilegeEscalation: false
      readOnlyRootFilesystem: true

Pod Security Policy - defines conditions for pod to be scheduled or prevented from being scheduled.

https://github.com/sysdiglabs/kube-psp-advisor - Help building an adaptive and fine-grained pod security policy

