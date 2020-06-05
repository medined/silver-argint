#!/bin/bash

echo "'tempest' is hard-coded as the cluster name."

CONTROLLER_IP=$(aws ec2 describe-instances --region $AWS_REGION --filters "Name=instance-state-name,Values=running" "Name=tag:Name,Values='tempest-controller-0'" --query 'Reservations[].Instances[].PublicIpAddress' --output text)

PKI_PEM=/home/medined/Downloads/pem/david-va-oit-cloud-k8s.pem

ssh -i $PKI_PEM core@$CONTROLLER_IP
