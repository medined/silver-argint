#!/bin/bash
HOSTED_ZONE_NAME=va-oit.cloud
HOSTED_ZONE_ID=$(aws route53 list-hosted-zones-by-name --query "HostedZones[?Name==\`$NAME.\`].Id" --output text)
REGISTRY_HOST=registry.$HOSTED_ZONE_NAME

docker login https://$REGISTRY_HOST -u admin --password-stdin < password-docker-registry.txt
