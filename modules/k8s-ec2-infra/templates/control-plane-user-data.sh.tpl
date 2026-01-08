#!/bin/bash
set -euo pipefail

AWS_REGION="${aws_region}"
K8S_VERSION_MINOR="${k8s_version_minor}"
POD_CIDR="${pod_cidr}"
SERVICE_CIDR="${service_cidr}"
CLUSTER_NAME="${cluster_name}"
JOIN_PARAMETER_NAME="${join_parameter_name}"
JOIN_PARAMETER_KMS_KEY_ID="${join_parameter_kms_key_id}"
INGRESS_NODEPORT="${ingress_nodeport}"

log() {
  echo "[$(date -Iseconds)] $*"
}

log "Installing dependencies"
dnf -y install containerd awscli curl jq conntrack socat iproute-tc iptables

cat <<REPO >/etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v$K8S_VERSION_MINOR/rpm/
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v$K8S_VERSION_MINOR/rpm/repodata/repomd.xml.key
REPO

dnf -y install kubelet kubeadm kubectl

cat <<MODULES >/etc/modules-load.d/k8s.conf
overlay
br_netfilter
MODULES

modprobe overlay
modprobe br_netfilter

cat <<SYSCTL >/etc/sysctl.d/99-k8s.conf
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
SYSCTL

sysctl --system

swapoff -a
sed -i '/ swap / s/^/#/' /etc/fstab

containerd config default > /etc/containerd/config.toml
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
systemctl enable --now containerd

TOKEN=$(curl -sX PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
PRIVATE_IP=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/local-ipv4)

printf 'KUBELET_EXTRA_ARGS=--node-ip=%s\n' "$PRIVATE_IP" > /etc/sysconfig/kubelet
systemctl enable --now kubelet
systemctl restart kubelet

if [ ! -f /etc/kubernetes/admin.conf ]; then
  log "Initializing control plane"
  kubeadm init \
    --pod-network-cidr "$POD_CIDR" \
    --service-cidr "$SERVICE_CIDR" \
    --apiserver-advertise-address "$PRIVATE_IP" \
    --cluster-name "$CLUSTER_NAME"

  mkdir -p /root/.kube
  cp /etc/kubernetes/admin.conf /root/.kube/config
  export KUBECONFIG=/etc/kubernetes/admin.conf

  log "Waiting for API server"
  for i in {1..30}; do
    if kubectl get nodes >/dev/null 2>&1; then
      break
    fi
    sleep 5
  done

  log "Installing CNI (flannel)"
  kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/v0.24.4/Documentation/kube-flannel.yml

  log "Installing ingress-nginx"
  kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.10.1/deploy/static/provider/baremetal/deploy.yaml

  for i in {1..30}; do
    if kubectl -n ingress-nginx get svc ingress-nginx-controller >/dev/null 2>&1; then
      break
    fi
    sleep 5
  done

  kubectl -n ingress-nginx patch service ingress-nginx-controller \
    --type='merge' \
    -p "{\"spec\": {\"type\": \"NodePort\", \"ports\": [{\"name\": \"http\", \"port\": 80, \"protocol\": \"TCP\", \"targetPort\": \"http\", \"nodePort\": $INGRESS_NODEPORT}]}}"
fi

log "Publishing kubeadm join command"
JOIN_CMD=$(kubeadm token create --print-join-command)
aws ssm put-parameter \
  --name "$JOIN_PARAMETER_NAME" \
  --type SecureString \
  --value "$JOIN_CMD" \
  --key-id "$JOIN_PARAMETER_KMS_KEY_ID" \
  --overwrite \
  --region "$AWS_REGION"

log "Control plane bootstrap complete"
