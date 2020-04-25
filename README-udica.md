# Introduction To Udica

Udica helps to generate SELinux policies for containers.

## Background

## Glossary

* MAC - Mandatory access controls.

* MCS - Multi-Category Security labels consist of two random numbers between 0 and 1,023 and have to be 
unique. They are prefixed with a c or category. SELinux also needs a sensitivity level s0. An example is
`s0:c1,c2`. The order of the numbers are not important.

* MCS Datastore - Each thing (such as LibVirt or Docker) that manages MCS labels has its own database 
so that labels can be tracked. Some tools (or toolchains) share an MCS database so they can read each 
others files. When tools do not share the same MCS datastore, labels can collide so it might be better to run 
them on separate  machines or use an orchestration tool like OpenShift or Kubernetes to provide guaranteed
label uniqueness.

* SELinux - Security-Enhanced Linux (SELinux) is a Linux kernel security module that provides a 
mechanism for supporting access control security policies, including mandatory access controls (MAC). 
SELinux is a set of kernel modifications and user-space tools that have been added to various 
Linux distributions. This emans a host can have about 500,000 unique containers.

* Sensitivity levels - These are hierarchical with (traditionally) s0 being the lowest. These 
values are defined using the sensitivity language statement. To define their hierarchy, the 
dominance statement is used. For MLS systems the highest sensitivity is the last one defined 
in the dominance statement (low to high).

* sVirt - Back in 2008, MCS labeling was created for virtual machines and they used this term.

* Type - Process and content are assigned to types. For example, Processes are usually run 
with the `container_t` type and content is created with the `container_file_t` type.

## Question

### When a container is restarted, does the SELinux labels changed?

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

# Type Glossary

| Software | Process | Files |
| ---------|-------- | ----- |
| LibVirt | svirt_t | svirt_image_t  |

# Links

* https://opensource.com/article/18/2/understanding-selinux-labels-container-runtimes
