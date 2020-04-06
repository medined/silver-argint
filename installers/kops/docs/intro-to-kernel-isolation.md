# Kernel Isolation

## Description

Kubernetes is the new kernel. We can refer to it as a “cluster kernel” versus the typical operating system kernel. This means a lot of great things for users trying to deploy applications. It also leads to a lot of the same challenges we have already faced with operating system kernels. One of which being privilege isolation. In Kubernetes, we refer to this as multi-tenancy, or the dream of being able to isolate tenants of a cluster.

The attack surface with the highest risk of logical vulnerabilities is the Kubernetes API. This must be isolated between tenants. The attack surface with the highest risk of remote code execution are the services running in containers. These must also be isolated between tenants.

A container is an isolated user-space environment which is often realized through the use of kernel features. Docker for example uses Linux namespaces, control groups and capabilities to achieve this. In this regard Docker containers isolate very differently compared to virtual machines powered by bare-metal hypervisors.

In such virtual machines the separation can be implemented as far down as in the actual hardware through for example Intel VT. Docker containers on the other hand rely on the Linux kernel for the separation. The Linux kernel has a large attack surface due to its size and range of functionality. A large attack surface implies more potential attack vectors for clouds relying on container isolation.

To increase isolation inside the container, security modules like SELinux or AppArmor could be used. Unfortunately, such kernel-based security mechanisms will not prevent kernel-based escape attacks. It would only restrict an attacker’s actions if an escape cannot be achieved. If we want to tackle container escapes we need some isolation mechanism either outside the container or even the kernel.

Before moving on, it is worth noting that bugs in Kubernetes can also impact the container isolation. This topic is beyond scope of this document.

It is also worth noting that every security decision is based on a risk assesement. Low-value data does not need the same vigorous protection as high-value data. This document is written for data whose loss or leakage will cause severe damage.

There are many kind of security related to Kubernetes. This document solely on protection of privilege escalation by processes - on Kernel Isolation using sandboxes.

## Physical Isolation

Before talking about software isolation using sandboxes, lets mention physical isolation. Kubernetes on AWS has a one-to-one correlation from nodes to EC2 instances. If two processes need to be physically isolated, the resource manifests can use anti-affinity to prevent process from being co-located on the same node using labels. You can think of anti-affinity as "repelling" processes. Alternatively, affinity can "pull" process to a node or a set of nodes. As one example, unclassified processes can be run on nodes that have an "unclassified" label. Using physical isolation reduces the blast radius of a data breach.

## Sandboxes

Container security is built on top of the two key building blocks, Linux namespace and Linux Control group (cgroup). Namespace creates a virtually isolated user space and gives an application its dedicated system resources such as file system, network stack, process id, and user id. In this isolated user space, the application controls the root directory of the file system starting with PID = 1 and may run as the root user. This abstracted userspace allows each application to run independently without interfering with other applications on the same host. There are currently six namespaces available:

* mount
* inter-process communication (ipc)
* UNIX time-sharing system (uts)
* process id (pid)
* network
* user

Two additional namespaces, time and syslog, are proposed but the Linux community are still defining the specifications. Cgroup enforces hardware resources limitation, prioritization, accounting, and controlling of an application. Example hardware resources that cgroup can control are CPU, memory, device, and network. When putting namespace and cgroup together, we can securely run multiple applications on a single host with each application residing in its isolated environment. This is the fundamental property of a container.

Security is all about layers. With each layer, an attacker should be presented with a new set of challenges. Two adjacent layers should be different from each other. With this in mind, the idea of a sandbox is frequently used to indicate a technique in which one process is enclosed by another. The sandbox, is designed to have a limited set of functionality. Importantly, it is not sourced from the same organization creating the process running inside the sandbox. The sandbox's security can be improved and controlled separately from the inner process. This separation of responsibilities is an important security concept.

## Sandbox Implementations

Different sandbox implementations have different performance characteristics. For example, one might been quicker to start than another. Like all other aspects of computing, one size does not fit all. Attention to use cases and judgment is needed to find the best solution for specific computing situations. Specifically, long-running processes like web servers might use a different sandbox than short-running processes that support function-as-a-service.

Since the industry moves quickly, don't consider any decisions as "once-and-done". Plans should be made to review decisions on a regular basis.

## distroless

TDB

## cri-o

TBD

### Openstack Kata Containers

In Kata, which only runs on Linux, each container runs its own kernel instead of sharing the host system’s kernel with the host and other containers using cgroups. By extension, each container also gets its own I/O, memory access, and other low-level resources, without having to share them.

In most cases, Kata containers can also take advantage of security features provided by hardware-level virtualization (meaning virtualization that is built into CPUs and made available using VT extensions).

Supported by Google, IBM, Microsoft, Canonical, Oracle, and many more.

### containerd

TBD

### gVisor

* https://gvisor.dev/

gVisor is an open-source, OCI-compatible sandbox runtime (from Google) that provides a virtualized container environment integrated with Kubernetes. It runs containers with a new user-space kernel, delivering a low overhead container security solution for high-density applications. gVisor creates a strong security boundary between an application and its host. This boundary restricts the syscalls that applications in user space can use. gVisor’s kernel written in Golang is more secure than the Linux kernel written in C due to the strong type safety and memory management features in Golang.

However, gVisor is still in its infancy. There is always overhead when gVisor intercepts and handles a syscall made by the sandboxed application, so it is not suitable for syscall heavy applications. Finally, as gVisor has not implemented all the Linux syscalls, applications that use unimplemented syscalls can’t run in gVisor.

gVisor should not be confused with technologies and tools to harden containers against external threats, provide additional integrity checks, or limit the scope of access for a service. One should always be careful about what data is made available to a container.

### Unikernel

* http://unikernel.org/

Unikernels break the kernel into multiple libraries and place only the application-dependent libraries into a single machine image. Like VMs, unikernels are deployed and run on virtual machine monitors. Due to their small footprints, unikernels can boot and scale up quickly. Unikernels’ most essential properties are improved security, small footprint, high optimization, and fast boot.

When Docker acquired a unikernel startup, Unikernel Systems, in 2016 people thought that Docker would package containers into unikernels. After 3 years, there is still no sign of any integration. One main reason for this slow adoption is that there is still no mature tool to build unikernel applications and most of the unikernel applications can only run on specific hypervisors.


------------------------------------------------------------------------------
------------------------------------------------------------------------------
------------------------------------------------------------------------------
------------------------------------------------------------------------------
------------------------------------------------------------------------------
------------------------------------------------------------------------------
------------------------------------------------------------------------------
------------------------------------------------------------------------------


## Links

### Isolation

* https://kubernetes.io/docs/tasks/administer-cluster/sysctl-cluster/
* https://medium.com/@chrismessiah/docker-and-kubernetes-in-high-security-environments-d851645e8b99
  * http://kth.diva-portal.org/smash/get/diva2:1231856/FULLTEXT02.pdf
* https://unit42.paloaltonetworks.com/making-containers-more-isolated-an-overview-of-sandboxed-container-technologies/
* https://www.magalix.com/blog/running-containers-securely-under-kubernetes
* https://sysdig.com/blog/container-isolation-gone-wrong/
* https://platform9.com/blog/kata-containers-docker-and-kubernetes-how-they-all-fit-together/

### Miscellany

```
kubetctl
  - cri-i
    - kata-runtime
      - pods

kubectl get runtimeclasses --all-namespaces

pod / spec / runtimeClass
```


### sysctl (modify kernel parameters at runtime)

Sysctls are grouped into safe and unsafe sysctls. In addition to proper namespacing, a safe sysctl must be properly isolated between pods on the same node. This means that setting a safe sysctl for one pod
* must not have any influence on any other pod on the node
* must not allow to harm the node’s health
* must not allow to gain CPU or memory resources outside of the resource limits of a pod.

By far, most of the namespaced sysctls are not necessarily considered safe. All safe sysctls are enabled by default. All unsafe sysctls are disabled by default and must be allowed manually by the cluster admin on a per-node basis. Pods with disabled unsafe sysctls will be scheduled, but will fail to launch.

### Other

* Nested Virtualization needed for kata containers
* Use Transport Security Layer (TLS) for all API traffic.
* Use service accounts with limited permissions.
* Enable kubelet authentication and authorization. It is allows unauthenticated access by default.
* Limt CPU, Memory, and Disk that can be allocated using quotas or ranges.
* Use pod security policies.
* Create kernel module blacklist (/etc/modprobe.d/kubernetes-blacklist.conf)
* Distroless has no kernel?
* Use network security policies.
* Use IAM rules to limit access to AWS resources.
* Restrict use of high-cost instances.

* https://kubernetes.io/docs/tasks/administer-cluster/securing-a-cluster/
* https://kubernetes.io/docs/tasks/administer-cluster/encrypt-data/
* https://www.stackrox.com/post/2019/09/12-kubernetes-configuration-best-practices/
* https://kubernetes.io/docs/reference/access-authn-authz/admission-controllers/#imagepolicywebhook
* https://kubernetes.io/docs/reference/access-authn-authz/admission-controllers/#alwayspullimages
* https://stupefied-goodall-e282f7.netlify.com/contributors/design-proposals/node/sysctl/
* Kubernetes Securuty Working Group Security Audit
  * https://github.com/kubernetes/community/blob/master/wg-security-audit/findings
* https://itnext.io/seccomp-in-kubernetes-part-i-7-things-you-should-know-before-you-even-start-97502ad6b6d6
* https://nvlpubs.nist.gov/nistpubs/SpecialPublications/NIST.SP.800-190.pdf