#!/bin/bash
# Run this script in both master node and worker node to create a cluster

Green='\033[0;32m'
Yellow='\033[0;33m'
NC='\033[0m'

# 1. Default setting
echo -e "${Yellow}🚀 Start default setting...${NC}"

# disable swap
sudo swapoff -a

# clean apt
sudo apt-get clean

# keeps the swaf off during reboot
(crontab -l 2>/dev/null; echo -e "@reboot /sbin/swapoff -a") | crontab - || true
sudo apt-get update -y
echo -e "${Green}✅ Default setting successfully${NC}"

# 2. Install CRI-O Runtime, which is a container runtime interface
echo -e "${Yellow}🚀 Start installing CRI-O...${NC}"
OS="xUbuntu_20.04"
VERSION="1.23"

# create the .conf file to load the modules at bootup process
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

# sysctl params required by setup, params persist across reboots
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

# apply sysctl params without reboot
sudo sysctl --system

# set up gnupg for secret file transferring
cat <<EOF | sudo tee /etc/apt/sources.list.d/devel:kubic:libcontainers:stable.list
deb [signed-by=/usr/share/keyrings/libcontainers-archive-keyring.gpg] https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/$OS/ /
EOF
cat <<EOF | sudo tee /etc/apt/sources.list.d/devel:kubic:libcontainers:stable:cri-o:$VERSION.list
deb [signed-by=/usr/share/keyrings/libcontainers-crio-archive-keyring.gpg] https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable:/cri-o:/$VERSION/$OS/ /
EOF

# get release through gnupg
mkdir -p /usr/share/keyrings
curl -L https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/$OS/Release.key | gpg --dearmor -o /usr/share/keyrings/libcontainers-archive-keyring.gpg
curl -L https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable:/cri-o:/$VERSION/$OS/Release.key | gpg --dearmor -o /usr/share/keyrings/libcontainers-crio-archive-keyring.gpg

# install CRI-O
sudo apt-get update
sudo apt-get install cri-o cri-o-runc -y

systemctl start crio
systemctl --no-pager status crio
echo -e "${Green}✅ CRI-O installed successfully${NC}"

# 3. Install kubelet, kubectl and Kubeadm
# install something about google cloud public signing key
echo -e "${Yellow}🚀 Start installing kubelet, kubectl and kubeadm...${NC}"
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl
sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg

# configure gnupg secret to transfer information to api package config
cat <<EOF | sudo tee /etc/apt/sources.list.d/kubernetes.list
deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main
EOF

# install all in fixed version
sudo apt-get update -y
sudo apt-get install -y kubelet="$KUBERNETES_VERSION" kubectl="$KUBERNETES_VERSION" kubeadm="$KUBERNETES_VERSION"
sudo apt-get update -y
sudo apt-get install -y jq
sudo apt-mark hold kubelet kubeadm kubectl
echo -e "${Green}✅ kubelet, kubectl and kubeadm are installed successfully${NC}"

# 4. Install helm
echo -e "${Yellow}🚀 Start installing helm...${NC}"
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh

echo -e "${Green}✅ helm is installed successfully${NC}"

# 5. Install cilium cli
CILIUM_CLI_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/master/stable.txt)
CLI_ARCH=amd64
if [ "$(uname -m)" = "aarch64" ]; then CLI_ARCH=arm64; fi
curl -L --fail --remote-name-all https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}
sha256sum --check cilium-linux-${CLI_ARCH}.tar.gz.sha256sum
sudo tar xzvfC cilium-linux-${CLI_ARCH}.tar.gz /usr/local/bin
rm cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}
