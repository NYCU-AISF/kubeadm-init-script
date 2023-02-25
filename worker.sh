#!/bin/bash

Green='\033[0;32m'
Yellow='\033[0;33m'
Red='\033[0;31m'
NC='\033[0m'

if [ "$EUID" -ne 0 ]
then
  echo -e "${Red}🚨 Please run as root${NC}"
  exit
fi

# check if token.sh file exist
if test -f "./token.sh";
then
    echo -e "${Green}✅ token.sh exists.${NC}"
else
    echo -e "${Red}🚨 token.sh does not exist.${NC}"
    exit
fi
source ./token.sh

# 1. Checking
echo -e "${Yellow}🚀 Start checking env...${NC}"
if [ "x${CONTROL_PLANE_IP}" == "x" ]; then
  echo -e "${Red}🚨 Need to specify env variable CONTROL_PLANE_IP${NC}"
  exit 1
fi
if [ "x${TOKEN}" == "x" ]; then
  echo -e "${Red}🚨 Need to specify env variable TOKEN${NC}"
  exit 1
fi
if [ "x${HASH_TOKEN}" == "x" ]; then
  echo -e "${Red}🚨 Need to specify env variable HASH_TOKEN${NC}"
  exit 1
fi
echo -e "${Green}✅ Finish checking env${NC}"

# 2. Join cluster
echo -e "${Yellow}🚀 Start resetting the cluster...${NC}"
# clean dirty port and setting
kubeadm reset
rm -rf /etc/cni
rm -rf /etc/kubernetes
systemctl daemon-reload
systemctl restart kubelet
iptables -F && iptables -t nat -F && iptables -t mangle -F && iptables -X
echo -e "${Green}✅ Finish resetting cluster${NC}"

echo -e "${Green}✅ Start joining the cluster${NC}"
kubeadm join "${CONTROL_PLANE_IP}":6443 --token "${TOKEN}" --discovery-token-ca-cert-hash "${HASH_TOKEN}"
echo -e "${Green}✅ Join cluster successfully${NC}"