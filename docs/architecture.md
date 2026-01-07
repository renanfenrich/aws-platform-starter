# Architecture

This platform provisions a two-AZ VPC with public and private subnets. The ALB sits in public subnets, while ECS Fargate and RDS run in private subnets. NAT gateways provide outbound access for tasks and patching.

Production uses one NAT gateway per AZ; dev defaults to a single NAT for cost.

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
      ECS[ECS Fargate Service]
      RDS[(RDS PostgreSQL)]
    end
  end

  ALB --> ECS
  ECS --> RDS
  ECS --> NAT1
  ECS --> NAT2
```

## Key Flows

- Inbound traffic terminates TLS at the ALB.
- ALB forwards requests to ECS tasks in private subnets.
- ECS tasks access RDS within the VPC.
- Secrets are retrieved from AWS Secrets Manager by the ECS execution role.
