#!/bin/bash

set -x; 
cd "$(mktemp -d)"
curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/latest/download/krew.{tar.gz,yaml}"
tar zxvf krew.tar.gz
KREW=./krew-"$(uname | tr '[:upper:]' '[:lower:]')_amd64"
"$KREW" install --manifest=krew.yaml --archive=krew.tar.gz
"$KREW" update

"$KREW" install df-pv
"$KREW" install outdated

grep ".krew/bin" $HOME/.bashrc
if [ $? != 0 ]; then
    echo 'export PATH="${PATH}:${HOME}/.krew/bin' >> $HOME/.bashrc
fi
