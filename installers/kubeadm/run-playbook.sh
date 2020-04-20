#!/bin/bash

python3 $(which ansible-playbook) \
    -i inventory \
    --private-key /tmp/david-va-oit-cloud-k8s.pem \
    -u core \
    main.playbook.yml
