#!/bin/bash

Green='\033[0;32m'
Yellow='\033[0;33m'
NC='\033[0m'

# 1. Install flannel(CNI)
echo "${Yellow}🚀 Start installing flannel(CNI)...${NC}"

# add flannel into cluster
kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml
sleep 5s
FILE=/etc/cni/net.d/flannel.conflist
if test -f "$FILE"; then
    echo "${Green}✅ $FILE exists.${NC}"
fi

# restart some service to enable cni
systemctl restart crio
systemctl restart kubelet
echo "${Green}✅ Flannel(CNI) installed successfully${NC}"
