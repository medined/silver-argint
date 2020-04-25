# Introduction To Udica

Udica is a tool for generating SELinux security profiles for containers.

## TL;DR

SELinux is a Linux module supporting security policies including mandatory access control. In this situation, "mandatory" means the user can't change the policy.

Learning to understand the security polices then to create and implement them does have a high learning curve. Security is inherently a complex topic.

As you'll see Udica can automate the process. However, without an understanding of the generated profile it will be impossible to audit the resulting policy. Because of this, Udica should only be used by people already familar with SELinux polices.

## Background

Security-Enhanced Linux is a Linux kernel security module that provides a mechanism for supporting access control security policies, including mandatory access controls. SELinux is a set of kernel modifications and user-space tools that have been added to various Linux distributions.

An SELinux Policy is the set of rules that guide the SELinux security engine. It defines types for file objects and domains for processes. It uses roles to limit the domains that can be entered, and has user identities to specify the roles that can be attained. In essence, types and domains are equivalent, the difference being that types apply to objects while domains apply to processes.

An SELinux type is a way of grouping items based on their similarity from a security perspective. This is not necessarily related to the unique purpose of an application or the content of a document. For example, a file can have any type of content and be for any purpose, but if it belongs to a user and exists in that user's home directory, it is considered to be of a specific security type, `user_home_t`.

Likewise, all containers are of type `container_t`. For example, we can look at information about a running pod. Notice the third element.

```
system_u:system_r:container_t:s0:c182,c897
```

There are some situations where using the same type is used for all containers does not meet requirements for a given use case. For illustration purposes, two different scenarios will be reviewed.

The `container_t` type allows containers to bind to any network port. This might be too permissive for your use case.

In another use case, a container might need read/write access to the home directory. This time, the `container_t` policy is too restrictive.

In both cases, changing `container_t` affects every container. What is needed is a per-container policy. This where Udica comes into play. It will help you create a security profile that can be used when the container is created.

## Glossary

Before reading farther you should be familiar with these terms.

* fsGroup - File system groups are typically used for controlling access to block storage such as Ceph and iSCSI. See supplementalGroups. Unlike shared storage, block storage is taken over by a pod, meaning that user and group IDs supplied in the pod definition (or image) are applied to the actual, physical block device. Typically, block storage is not shared. It is generally preferable to use group IDs (supplemental or fsGroup) to gain access to persistent storage versus using user IDs.

* MAC - Mandatory access controls.

* MCS - Multi-Category Security labels consist of two random numbers between 0 and 1,023 and have to be 
unique. They are prefixed with a c or category. SELinux also needs a sensitivity level s0. An example is
`s0:c1,c2`. The order of the numbers are not important.

* MCS Datastore - Each thing (such as LibVirt or Docker) that manages MCS labels has its own database 
so that labels can be tracked. Some tools (or toolchains) share an MCS database so they can read each 
others files. When tools do not share the same MCS datastore, labels can collide so it might be better to run 
them on separate  machines or use an orchestration tool like OpenShift or Kubernetes to provide guaranteed
label uniqueness.

* RunAsAny - This strategry means that a pod has carte blanche. For Docker, this means running as `root` unless a user id is specified. This also means that no SELinux labels are defined, so unique labels will be assigned.

* Security Context - Part of the pod specification.

* SCC - Security Context Constraint in OpenShift. It is often better to create a new SCC rather than modifying a predefined SCC to reduce the potential of privilege escalation.

* SELinux - Security-Enhanced Linux (SELinux) is a Linux kernel security module that provides a 
mechanism for supporting access control security policies, including mandatory access controls (MAC). 
SELinux is a set of kernel modifications and user-space tools that have been added to various 
Linux distributions. This emans a host can have about 500,000 unique containers.

* Sensitivity levels - These are hierarchical with (traditionally) s0 being the lowest. These 
values are defined using the sensitivity language statement. To define their hierarchy, the 
dominance statement is used. For MLS systems the highest sensitivity is the last one defined 
in the dominance statement (low to high).

* supplementalGroups - Supplemental groups are typically used for controlling access to shared storage such as NFS. See fsGroup. It is generally preferable to use group IDs (supplemental or fsGroup) to gain access to persistent storage versus using user IDs.

* sVirt - Back in 2008, MCS labeling was created for virtual machines and they used this term.

* Type - Process and content are assigned to types. For example, Processes are usually run 
with the `container_t` type and content is created with the `container_file_t` type.

## Installing Udica

Ideally, udica should be installed on the Kubernetes nodes already. If not, this is the manual process for Fedora CoreOS. Several auditing tools should be installed in addition to udica so that you can troubleshoot. After the packages are installed, the node must be rebooted. Make sure to always use the same node for your testing. Alteratively, you can use the `start-fcos-instance.sh` script to start a Fedora CoreOS server which is not in a Kubernetes cluster to practice with.

```
sudo rpm-ostree install audit libselinux-python3 setools setroubleshoot udica
sudo systemctl reboot
```

## Show Restrictive Policy

Start a container that wants to read from `/home` but can't because the the SELinux policy.

```bash
podman run -v /home:/home:ro -it fedora ls -l /home
cat: /home: Permission denied.
```

## Create Permissive Policy

In one SSH session, start a container that does not stop immediately.

```bash
podman run -v /home:/home:ro -it fedora bash
```

In another SSH session, 

```bash
$ podman inspect xyz | udica xyz
```

Before moving on, let us look at the MSC label for the container. Notice that it is `container_t`. Our goal is to create our own type.

```bash
podman top -l label
system_u:system_r:container_t:s0:c182,c897
```

You can now exit the first container. The second command created a file called xyz.cil. It looks like this:

```
(block xyz
  (blockinherit container)
    (allow process process 
      (capability 
        (
          chown dac_override fsetid fowner mknod net_raw 
          setgid setuid setfcap setpcap net_bind_service 
          sys_chroot kill audit_write
        )
      )
    )
    (blockinherit home_container)
)
```

NOTE: At this point, unless you have prior experience you've crossed into unknown territory. What does "blockinherit container" mean? A web search does not provide a ready answer. Also, how do you really know that 14 capacities are needed?

In order to activate the policy, run the following command.

```bash
sudo semodule -i xyz.cil /usr/share/udica/templates/{base_container.cil,home_container.cil}
```

```bash
podman run --security-opt label=type:xyz.process -v /home:/home:ro -it fedora ls -l /home
total 0
drwx------. 5 root root 198 Apr 25 20:43 core
```

Now the container is permitted to access the home directory. However, let's make sure that /home is still read-only.

```bash
podman run -v /home:/home:ro -it fedora touch /home/xyz
touch: cannot touch '/home/xyz': Read-only file system
```

We can confirm the container is running with our new label. Start a container that does not immediately exist.

```bash
podman run --security-opt label=type:xyz.process -v /home:/home:ro -it fedora bash
```

Check its labels. The container is using the new `xyz.process` label.

```bash
podman top -l label
LABEL
system_u:system_r:xyz.process:s0:c103,c533
```

## Question

### When a container is restarted, are the SELinux labels changed?

No, Container runtimes do not destroy the "container" when the processes in the container stop. They 
record the information on how to run the container, including the SELinux labels used to run them. So, 
when you stop and start a container, it will always run with the same MCS label. Not only that, but 
the container runtimes also read their database or existing containers when they start, reserving 
the MCS labels that are already used, so they can guarantee that all new containers will not 
conflict with already reserved MCS labels.

### Changing MSC Labels

Containers get a pair of randomly chosen MCS [Multi-Category Security] labels by default, and that the files they 
create obviously end up with those same categories. However, when it's time to rebuild or upgrade the container, 
the files are now inaccessible because the new container has a different pair of categories.

### How To Set SELinux Labels Per Pod

```
 securityContext: 
    seLinuxOptions:
      level: "s0:c123,c456" 
```

# Type Glossary

| Software | Process | Files |
| ---------|-------- | ----- |
| LibVirt | svirt_t | svirt_image_t  |
| RHEL v7.5+ | | container_file_t |
| RHEL v7.4- | | svirt_sandbox_file_t |

# Troubleshooting

## ausearch

If `ausearch` is installed.

```bash
ausearch -m avc --start recent
```

## Display SELinux Label For Container

This command is run on the security running the images.

```bash
podman top --l label
LABEL
system_u:system_r:container_t:s0:c342,c861
```

## sestatus

```bash
$ sestatus
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

# Links

* https://opensource.com/article/18/2/understanding-selinux-labels-container-runtimes
* https://www.youtube.com/watch?v=FOny29a31ls - Using SELinux with container runtimes. Udica is mentioned starting at 19:40.
