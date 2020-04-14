#!/bin/bash

[ -d $HOME/bin ] || mkdir $HOME/bin
grep "^export PATH=[$]PATH:[$]HOME/bin$" $HOME/.bashrc > /dev/null
if [ $? != 0 ]; then
    echo 'export PATH=$PATH:$HOME/bin' >> $HOME/.bashrc
fi

if [ -f $HOME/bin/krew ]; then
    echo "krew: already installed"
    exit
fi

# We'll need this path, so might as well do it first.
grep ".krew/bin" $HOME/.bashrc
if [ $? != 0 ]; then
    echo 'export PATH="${PATH}:${HOME}/.krew/bin"' >> $HOME/.bashrc
    export PATH="${PATH}:${HOME}/.krew/bin
fi

# Switch to the /tmp directory so that we'll pop back to the right directory later.
pushd /tmp > /dev/null

cd "$(mktemp -d)"
CURRENT_DIR=$(pwd)

curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/latest/download/krew.{tar.gz,yaml}"
tar zxvf krew.tar.gz
KREW=./krew-"$(uname | tr '[:upper:]' '[:lower:]')_amd64"
"$KREW" install --manifest=krew.yaml --archive=krew.tar.gz
"$KREW" update

"$KREW" install df-pv
"$KREW" install outdated

cp "$KREW" $HOME/bin/krew

popd
rm -rf $CURRENT_DIR
