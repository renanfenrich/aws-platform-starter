# Architecture

If I were sketching this on a whiteboard, I would start at the edge and walk inward:

1) The user hits the ALB in the public subnets. TLS terminates here. HTTP only exists when `allow_http = true` in dev.
2) The ALB forwards to the compute layer in private subnets. ECS tasks run with capacity providers: Fargate (prod default), Fargate Spot (dev default with Fargate fallback), or an EC2 capacity provider.
3) Compute talks to RDS in private subnets. The DB security group only allows traffic from the compute security group.
4) For outbound internet access (image pulls, patches, external APIs), compute traffic goes through NAT gateways. Dev uses a single NAT; prod uses one per AZ.

RDS manages the master password and stores it in Secrets Manager. ECS tasks retrieve it via the execution role; EC2 container instances are SSM-enabled for access when needed.

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
      Compute[Compute : ECS (Fargate, Fargate Spot, or EC2 capacity provider)]
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
