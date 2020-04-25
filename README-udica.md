# Introduction To Udica

Udica helps to generate SELinux policies for containers.

## Background

## Glossary

* MAC - Mandatory access controls.

* MCS - Multi-Category Security labels consist of two random numbers between 0 and 1,023 and have to be 
unique. They are prefixed with a c or category. SELinux also needs a sensitivity level s0. An example is
`s0:c1,c2`. The order of the numbers are not important.

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

## 

## Problem To Be Solved

The `container_t` 

### Changing MSC Labels

Containers get a pair of randomly chosen MCS [Multi-Category Security] labels by default, and that the files they 
create obviously end up with those same categories. However, when it's time to rebuild or upgrade the container, 
the files are now inaccessible because the new container has a different pair of categories.


