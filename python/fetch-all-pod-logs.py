#!/usr/bin/env python

from kubernetes.client.rest import ApiException
from kubernetes import client, config

# Configs can be set in Configuration class directly or using helper utility
config.load_kube_config()

v1 = client.CoreV1Api()

ret = v1.list_pod_for_all_namespaces(watch=False)
for i in ret.items:
    namespace = i.metadata.namespace
    pod_name = i.metadata.name
    print("---------------------------------------------------------------")
    print("%s\t%s" % (namespace, pod_name))
    print("---------------------------------------------------------------")
    try:
        api_response = v1.read_namespaced_pod_log(name=pod_name, namespace=namespace)
        print(api_response)
    except ApiException as e:
        print('Found exception in reading the logs')
