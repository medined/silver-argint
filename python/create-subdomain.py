#!/usr/bin/env python

"""
Creates a sub-domain in Route53. For example, qwerty.va-oit.cloud.
"""

import argparse
import uuid
import boto3


def get_hosted_zone_id(_client, _domain_name):
    _response = _client.list_hosted_zones_by_name()
    if _response is None:
        raise RuntimeError("Unable to list hosted zones.")
    _hosted_zone_ids = [_hosted_zone['Id'] for _hosted_zone in _response['HostedZones'] if _hosted_zone['Name'] == '{}.'.format(_domain_name)]
    if _hosted_zone_ids:
        return _hosted_zone_ids[0]
    return None


parser = argparse.ArgumentParser(description='Create a sub-domain hosted by Route53.')
required = parser.add_argument_group('required named arguments')
required.add_argument('--domain-name', help='the base domain name (i.e. va-oit.cloud)', required=True)
required.add_argument('--sub-domain-name', help='the sub-domain name (i.e. qwerty.va-oit.cloud)', required=True)

args = parser.parse_args()
domain_name = args.domain_name
sub_domain_name = args.sub_domain_name

client = boto3.client('route53')

# 1. Create Hosted Zone For Sub-domain.

domain_hosted_zone_id = get_hosted_zone_id(client, domain_name)
if domain_hosted_zone_id is None:
    raise RuntimeError("Missing domain name - {}".format(domain_name))

sub_domain_hosted_zone_id = get_hosted_zone_id(client, sub_domain_name)
if sub_domain_hosted_zone_id is None:
    caller_reference = str(uuid.uuid4())
    response = client.create_hosted_zone(Name=sub_domain_name, CallerReference=caller_reference)
    if response is None:
        raise RuntimeError("Unable to create hosted zone - {}".format(domain_name))
    sub_domain_hosted_zone_id = response['HostedZone']['Id']
    nameservers = response['DelegationSet']['NameServers']
else:
    response = client.get_hosted_zone(Id=sub_domain_hosted_zone_id)
    if response is None:
        raise RuntimeError("Unable to get hosted zone info - {}".format(sub_domain_name))
    nameservers = response['DelegationSet']['NameServers']

# Add periods to the end of the nameservers.

nameservers = ['{}.'.format(nameserver) for nameserver in nameservers]
nameserver_resource_records = [{'Value': nameserver} for nameserver in nameservers]

# 2. Create Record Set in Domain Pointing To Sub-domain.

response = client.change_resource_record_sets(
    HostedZoneId=domain_hosted_zone_id,
    ChangeBatch={
        'Changes': [
            {
                'Action': 'UPSERT',
                'ResourceRecordSet': {
                    'Name': sub_domain_name,
                    'Type': 'NS',
                    'TTL': 60,
                    'ResourceRecords': nameserver_resource_records
                }
            }
        ]
    }
)

if response is None:
    raise RuntimeError("Unable to upsert resource record set for sub-domain in domain.")
