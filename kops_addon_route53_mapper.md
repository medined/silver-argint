

cat <<EOF >yaml/kops_addon_route53_mapper_v1_3_0.yaml
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: route53-mapper
  namespace: kube-system
  labels:
    app: route53-mapper
    k8s-addon: route53-mapper.addons.k8s.io
spec:
  replicas: 1
  selector:
    matchLabels:
      app: route53-mapper
  template:
    metadata:
      labels:
        app: route53-mapper
      annotations:
        scheduler.alpha.kubernetes.io/tolerations: '[{"key":"dedicated", "value":"master"}]'
    spec:
      nodeSelector:
        kubernetes.io/role: master
      containers:
        - image: quay.io/molecule/route53-kubernetes:v1.3.0
          name: route53-mapper
EOF
kubectl apply -f yaml/kops_addon_route53_mapper_v1_3_0.yaml

# The official version of this addon has a non-working apiVersion.
#kubectl apply -f https://raw.githubusercontent.com/kubernetes/kops/master/addons/route53-mapper/v1.3.0.yml
