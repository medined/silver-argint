
POD=$(kubectl get pods \
  --namespace sandbox \
  -l 'app.kubernetes.io/instance=jenkins' \
  -o jsonpath="{.items[0].metadata.name}")
echo "Jenkins Pod: $POD"

kubectl \
  --namespace sandbox \
  port-forward \
  $POD \
  8080:8080
