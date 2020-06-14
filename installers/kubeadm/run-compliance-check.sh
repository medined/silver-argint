python3 /data/projects/ic1/silver-argint/installers/kubeadm/venv/bin/ansible-playbook     --check     -i inventory     --private-key /home/medined/Downloads/pem/david-va-oit-cloud-k8s.pem     -u core     ocp4-playbook-coreos-ncp.yml | tee compilance.txt
grep "changed" compilance.txt | wc -l > compliance.count.txt
grep "changed" compilance.txt -B 1 > compilance.changed.txt

echo "Number of Changes"
echo "-----------------"
cat compliance.count.txt
