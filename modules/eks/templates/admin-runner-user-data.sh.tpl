#!/bin/bash
set -euo pipefail

if command -v dnf >/dev/null 2>&1; then
  dnf -y install awscli
else
  yum -y install awscli
fi

curl -L -o /tmp/kubectl "https://dl.k8s.io/release/v${kubectl_version}/bin/linux/amd64/kubectl"
install -o root -g root -m 0755 /tmp/kubectl /usr/local/bin/kubectl
rm -f /tmp/kubectl

mkdir -p /home/ec2-user/.kube
chown ec2-user:ec2-user /home/ec2-user/.kube

cat <<EOH >/usr/local/bin/eks-kubeconfig
aws eks update-kubeconfig --name ${cluster_name} --region ${aws_region} --kubeconfig /home/ec2-user/.kube/config
EOH

chmod +x /usr/local/bin/eks-kubeconfig
