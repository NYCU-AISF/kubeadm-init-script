#!/bin/bash

Green='\033[0;32m'
Yellow='\033[0;33m'
Red='\033[0;31m'
NC='\033[0m'

# 1. Checking
echo "${Yellow}🚀 Start checking env...${NC}"
if [ x"${CONTROL_PLANE_IP}" == "x" ]; then
  echo "${Red}🚨 Need to specify env variable CONTROL_PLANE_IP${NC}"
  exit 1
fi
if [ x"${TOKEN}" == "x" ]; then
  echo "${Red}🚨 Need to specify env variable TOKEN${NC}"
  exit 1
fi
if [ x"${HASH_TOKEN}" == "x" ]; then
  echo "${Red}🚨 Need to specify env variable HASH_TOKEN${NC}"
  exit 1
fi
echo "${Green}✅ Finish checking env${NC}"

# 2. Join cluster
echo "${Yellow}🚀 Start installing flannel(CNI)...${NC}"
kubeadm join "${CONTROL_PLANE_IP}":6443 --token "${TOKEN}" --discovery-token-ca-cert-hash "${HASH_TOKEN}"
echo "${Green}✅ Flannel(CNI) installed successfully${NC}"

# 3. Install flannel(CNI)
echo "${Yellow}🚀 Start installing flannel(CNI)...${NC}"

# add flannel into cluster
kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml
sleep 5s
FILE=/etc/cni/net.d/flannel.conflist
if test -f "$FILE"; then
    echo "${Green}✅ $FILE exists.${NC}"
fi

# restart some service to enable CNI
systemctl restart crio
systemctl restart kubelet
echo "${Green}✅ Flannel(CNI) installed successfully${NC}"
