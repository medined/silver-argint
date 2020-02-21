#!/bin/bash

./kill-jenkins-proxy.sh

helm uninstall jenkins --namespace sandbox
