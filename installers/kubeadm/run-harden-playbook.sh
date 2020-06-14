#!/bin/bash

python3 \
  /data/projects/ic1/silver-argint/installers/kubeadm/venv/bin/ansible-playbook \
  --extra-vars ssm_binary_dir=/data/projects/dva/amazon-ssm-agent/bin \
  -i inventory \
  --private-key /home/medined/Downloads/pem/david-va-oit-cloud-k8s.pem \
  -u core \
  playbook.harden.yml
