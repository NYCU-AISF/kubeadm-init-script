#!/bin/bash

# auth cli with config
if [ "$EUID" -ne 0 ]
then
  mkdir -p "$HOME"/.kube
  sudo cp -i /etc/kubernetes/admin.conf "$HOME"/.kube/config
  sudo chown "$(id -u)":"$(id -g)" "$HOME"/.kube/config
else
  export KUBECONFIG=/etc/kubernetes/admin.conf
fi
