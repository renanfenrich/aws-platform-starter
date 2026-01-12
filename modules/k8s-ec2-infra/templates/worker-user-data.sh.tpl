#!/bin/bash
set -euo pipefail

AWS_REGION="${aws_region}"
K8S_VERSION_MINOR="${k8s_version_minor}"
JOIN_PARAMETER_NAME="${join_parameter_name}"

log() {
  echo "[$(date -Iseconds)] $*"
}

log "Installing dependencies"
dnf -y install containerd awscli amazon-ecr-credential-helper curl jq conntrack socat iproute-tc iptables

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

log "Configuring ECR credential helper"
ECR_REFRESH_SCRIPT="/usr/local/bin/ecr-credential-helper-refresh"
cat <<'EOF' > "$ECR_REFRESH_SCRIPT"
#!/bin/bash
set -euo pipefail

AWS_REGION="${aws_region}"

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text --region "$AWS_REGION")
ECR_REGISTRY="$ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"
ECR_AUTH=$(echo "https://$ECR_REGISTRY" | docker-credential-ecr-login get)
ECR_USERNAME=$(echo "$ECR_AUTH" | jq -r '.Username')
ECR_PASSWORD=$(echo "$ECR_AUTH" | jq -r '.Secret')

sed -i '/# BEGIN ECR AUTH/,/# END ECR AUTH/d' /etc/containerd/config.toml

cat <<EOT >> /etc/containerd/config.toml
# BEGIN ECR AUTH
[plugins."io.containerd.grpc.v1.cri".registry.configs."$ECR_REGISTRY".auth]
  username = "$ECR_USERNAME"
  password = "$ECR_PASSWORD"
# END ECR AUTH
EOT

systemctl restart containerd
EOF

chmod 0755 "$ECR_REFRESH_SCRIPT"
"$ECR_REFRESH_SCRIPT"

cat <<EOF >/etc/systemd/system/ecr-credential-refresh.service
[Unit]
Description=Refresh ECR credentials for containerd
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=$ECR_REFRESH_SCRIPT
EOF

cat <<EOF >/etc/systemd/system/ecr-credential-refresh.timer
[Unit]
Description=Refresh ECR credentials for containerd

[Timer]
OnBootSec=5min
OnUnitActiveSec=6h
Unit=ecr-credential-refresh.service

[Install]
WantedBy=timers.target
EOF

systemctl daemon-reload
systemctl enable --now ecr-credential-refresh.timer

TOKEN=$(curl -sX PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
PRIVATE_IP=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/local-ipv4)

printf 'KUBELET_EXTRA_ARGS=--node-ip=%s\n' "$PRIVATE_IP" > /etc/sysconfig/kubelet
systemctl enable --now kubelet
systemctl restart kubelet

if [ ! -f /etc/kubernetes/kubelet.conf ]; then
  log "Waiting for join command"
  JOIN_CMD=""
  for i in {1..60}; do
    JOIN_CMD=$(aws ssm get-parameter \
      --name "$JOIN_PARAMETER_NAME" \
      --with-decryption \
      --query 'Parameter.Value' \
      --output text \
      --region "$AWS_REGION" 2>/dev/null || true)

    if [ -n "$JOIN_CMD" ] && [ "$JOIN_CMD" != "None" ]; then
      break
    fi
    sleep 10
  done

  if [ -z "$JOIN_CMD" ] || [ "$JOIN_CMD" = "None" ]; then
    log "Join command not available; exiting"
    exit 1
  fi

  log "Joining cluster"
  eval "$JOIN_CMD"
fi

log "Worker bootstrap complete"
