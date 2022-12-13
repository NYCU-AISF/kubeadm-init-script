#!/bin/bash

Green='\033[0;32m'
Yellow='\033[0;33m'
NC='\033[0m'

# 1. Default setting
echo "${Yellow}🚀 Start init cluster...${NC}"
# should record the token and hash token
kubeadm init --pod-network-cidr=10.244.0.0/16 | tee kubeadm-init.log
echo "${Green}✅ Cluster init successfully${NC}"

# 2. Install flannel(CNI)
echo "${Yellow}🚀 Start installing flannel(CNI)...${NC}"

# add flannel into cluster
kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml
sleep 5s
FILE=/etc/cni/net.d/flannel.conflist
if test -f "$FILE"; then
    echo "${Green}✅ $FILE exists.${NC}"
fi
kubectl get pod -A

# restart some service to enable CNI
systemctl restart crio
systemctl restart kubelet
kubectl rollout restart -n kube-system deployment/coredns
kubectl get nodes
echo "${Green}✅ Flannel(CNI) installed successfully${NC}"

# 3. Install nginx ingress
echo "${Yellow}🚀 Start adding nginx ingress controller...${NC}"

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
echo "${Green}✅ Nginx ingress is added successfully${NC}"
