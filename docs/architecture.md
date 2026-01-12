# Architecture

If I were sketching this on a whiteboard, I would start at the edge and walk inward:

1) The user hits the ALB in the public subnets. TLS terminates here. HTTP only exists when `allow_http = true` in dev.
2) The ALB forwards to the compute layer in private subnets. Compute runs either as ECS tasks with capacity providers (Fargate, Fargate Spot, or EC2 capacity provider) or as a self-managed Kubernetes cluster on EC2. For Kubernetes, the ALB forwards to a NodePort on worker nodes backed by an ingress controller.
3) Container images live in an environment-scoped ECR repository. ECS tasks and Kubernetes nodes pull from ECR using IAM roles and a credential helper on the nodes.
4) Compute talks to RDS in private subnets. The DB security group only allows traffic from the compute security group.
5) For outbound internet access (image pulls, patches, external APIs), compute traffic goes through NAT gateways. Dev uses a single NAT; prod uses one per AZ.

RDS manages the master password and stores it in Secrets Manager. ECS tasks retrieve it via the execution role; EC2 container instances and Kubernetes nodes are SSM-enabled for access when needed.

For `k8s_self_managed`, kubeadm boots a single control plane instance. The join command is stored in SSM Parameter Store so worker nodes can join without public SSH.

```mermaid
flowchart TB
  User((User)) --> ALB[ALB : HTTPS]

  subgraph VPC
    subgraph PublicSubnets[Public Subnets x2]
      ALB
      NAT1[NAT GW]
      NAT2[NAT GW]
    end

    subgraph PrivateSubnets[Private Subnets x2]
      Compute[Compute : ECS or self-managed Kubernetes on EC2]
      RDS[(RDS PostgreSQL)]
    end
  end

  ALB --> Compute
  Compute --> RDS
  Compute --> NAT1
  Compute --> NAT2
```

## Notes

- The ALB is the only public entry point.
- Compute and RDS are private by default; only the ALB and NAT gateways are exposed to the internet.
- Outbound traffic from the compute layer is the main reason NAT gateways exist here.
