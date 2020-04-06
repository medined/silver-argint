# Introduction

This project documents my exploration into [kubernets](https://kubernetes.io/). Each goal shown below is fairly simple and intended to be short and declarative. You'll need to read the orginal source material by following the links in each article to learn context.


## Kubernetes Installers

There are several ways to create a Kubernetes cluster.

## kops

This is a popular installer which is part of the Kubernetes project. It will handle doing the provisioning and software installation. Unfortunately, as of 2020-04-06, it does not support Fedora CoreOS. It does support CoreOS which is end-of-life.

See the [Kops readme](installers/kops/README.md).

## Typhoon

Typhoon is a minimal and free Kubernetes distribution. It was largely written by Dalton Hubble who worked on CoreOS for a couple of years before moving to Lyft.

See the [Typhoon readme](installers/typhoon/README.md).

## Research

See [Research](README-research.md)
