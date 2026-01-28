# Tests

This repo uses `terraform test` with mock providers and backendless init to keep CI free of AWS credentials.

## Coverage Matrix

### Root stacks
| Stack | Test harness | Modes covered | Regression targets |
| --- | --- | --- | --- |
| `bootstrap/` | `bootstrap/bootstrap.tftest.hcl` | N/A | State bucket encryption, public access block, SNS KMS encryption, optional replication wiring |
| `environments/dev/` | `environments/dev/stack.tftest.hcl` | `platform=ecs` (`fargate`, `fargate_spot`, `ec2`), `platform=k8s_self_managed`, `platform=eks` | Selector wiring, ECR defaults, VPC endpoint defaults, tag propagation on app SG, ECS vs K8s/EKS outputs, NodePort output wiring, budget creation, cost posture validation, deploy-time cost enforcement |
| `environments/prod/` | `environments/prod/stack.tftest.hcl` | `platform=ecs` (`fargate`, `fargate_spot`, `ec2`), `platform=k8s_self_managed`, `platform=eks` | Selector wiring, HTTP listener disabled in prod, VPC endpoints and flow logs enabled, ECS vs K8s/EKS outputs, NodePort output wiring, budget creation, spot override guard, cost posture validation, deploy-time cost enforcement |
| `environments/dr/` | `environments/dr/stack.tftest.hcl` | `platform=ecs` | Pilot-light defaults (desired_count=0, public ingress disabled), DR backup vault toggle, replication flags default-off |

### Modules
| Module | Test harness | Key assertions |
| --- | --- | --- |
| `modules/backup-vault` | `modules/backup-vault/backup-vault.tftest.hcl` | KMS encryption, key rotation, vault wiring |
| `modules/network` | `modules/network/network.tftest.hcl` | Subnet counts, NAT gateway count, flow logs enabled, name_prefix + tags, input validation |
| `modules/alb` | `modules/alb/alb.tftest.hcl` | HTTPS listener + ACM, public ingress toggle, subnet wiring, SG ingress, target group config, tags, input validation |
| `modules/apigw-lambda` | `modules/apigw-lambda/apigw-lambda.tftest.hcl` | HTTP API routes, Lambda VPC config, log retention, optional RDS egress, X-Ray toggle |
| `modules/ecs` | `modules/ecs/ecs.tftest.hcl` | No public IPs, container insights default, autoscaling toggles, tag presence, input validation |
| `modules/ecs-ec2-capacity` | `modules/ecs-ec2-capacity/ecs-ec2-capacity.tftest.hcl` | No public IPs, IMDSv2 required, tag propagation |
| `modules/eks` | `modules/eks/eks.tftest.hcl` | Private API endpoint default, node group subnet wiring, no public SSH, tags |
| `modules/k8s-ec2-infra` | `modules/k8s-ec2-infra/k8s-ec2-infra.tftest.hcl` | No public SSH, KMS key rotation, name_prefix, input validation |
| `modules/rds` | `modules/rds/rds.tftest.hcl` | Storage encryption, private by default, managed credentials, KMS rotation, backup plan wiring, name_prefix, tags |
| `modules/observability` | `modules/observability/observability.tftest.hcl` | Alarm thresholds/evaluation periods, SNS actions, missing-data behavior, input validation |

### Selector coverage
| Selector | Values covered |
| --- | --- |
| `platform` | `ecs`, `k8s_self_managed`, `eks`, invalid value rejected |
| `ecs_capacity_mode` | `fargate`, `fargate_spot`, `ec2`, invalid value rejected |

## Remaining Gaps (Ranked)
1. CLOSED: Plan-wide mandatory tag sweep enforced via `terraform test` plan JSON assertions.
2. CLOSED: Plan-wide forbidden security posture sweep (SSH 0.0.0.0/0) enforced via `terraform test` plan JSON assertions.
3. Plan JSON assertions are plan-only; runtime state and apply-time computed values are out of scope.
4. Coverage is limited to the modes exercised in the Coverage Matrix; optional paths not enabled in those runs are not evaluated.

## How To Run
- `make test`

Expected behavior: Terraform tests run plan-only with mock providers across bootstrap, `tests/terraform`, environments, and selected modules. No state backend is required and no AWS credentials are used.

For new test scaffolding examples, see `examples/testing/README.md`.
