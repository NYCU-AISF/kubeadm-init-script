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

# 1. Default setting
echo -e "${Yellow}🚀 Start init cluster...${NC}"
# clean previous cluster
kubeadm reset
rm -rf /etc/cni/
rm -rf /etc/kubernetes/
# should record the token and hash token
kubeadm init --pod-network-cidr=10.244.0.0/16 | tee kubeadm-init.log

# auth cli with config
export KUBECONFIG=/etc/kubernetes/admin.conf

# 2. Install flannel(CNI)
echo -e "${Yellow}🚀 Start installing flannel(CNI)...${NC}"

# add flannel into cluster
kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml
sleep 5s
FILE=/etc/cni/net.d/flannel.conflist
if test -f "$FILE"; then
    echo -e "${Green}✅ $FILE exists.${NC}"
fi
kubectl get pod -A

# restart some service to enable CNI
systemctl restart crio
systemctl --no-pager status crio
systemctl restart kubelet
systemctl --no-pager status kubelet
kubectl rollout restart -n kube-system deployment/coredns
kubectl get nodes
echo -e "${Green}✅ Flannel(CNI) installed successfully${NC}"

# 3. Install nginx ingress
echo -e "${Yellow}🚀 Start adding nginx ingress controller...${NC}"

# add nginx ingress controller to cluster
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.2.1/deploy/static/provider/cloud/deploy.yaml
kubectl get pod -n ingress-nginx

# install metalLB
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.9.6/manifests/namespace.yaml
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.9.6/manifests/metallb.yaml
# On first install only
kubectl create secret generic -n metallb-system memberlist --from-literal=secretkey="$(openssl rand -base64 128)"

# turn off the webhook admission service of nginx ingress
kubectl delete -A ValidatingWebhookConfiguration ingress-nginx-admission
echo -e "${Green}✅ Nginx ingress is added successfully${NC}"
