# Tests

This repo uses `terraform test` with mock providers and `-backend=false` to keep CI free of AWS credentials.

## Coverage Matrix

### Root stacks
| Stack | Test harness | Modes covered | Regression targets |
| --- | --- | --- | --- |
| `bootstrap/` | `bootstrap/bootstrap.tftest.hcl` | N/A | State bucket encryption, public access block, SNS KMS encryption |
| `environments/dev/` | `environments/dev/stack.tftest.hcl` | `platform=ecs` (`fargate`, `fargate_spot`, `ec2`), `platform=k8s_self_managed` | Selector wiring, subnet counts, tag propagation on app SG, ECS vs K8s outputs, reserved `eks` guard, budget creation, cost posture validation, deploy-time cost enforcement |
| `environments/prod/` | `environments/prod/stack.tftest.hcl` | `platform=ecs` (`fargate`, `fargate_spot`, `ec2`), `platform=k8s_self_managed` | Selector wiring, HTTP listener disabled in prod, ECS vs K8s outputs, budget creation, spot override guard, cost posture validation, deploy-time cost enforcement |

### Modules
| Module | Test harness | Key assertions |
| --- | --- | --- |
| `modules/network` | `modules/network/network.tftest.hcl` | Subnet counts, NAT gateway count, flow logs enabled, name_prefix and tags |
| `modules/ecs` | `modules/ecs/ecs.tftest.hcl` | No public IPs, container insights default, name_prefix, tag presence, input validation |
| `modules/ecs-ec2-capacity` | `modules/ecs-ec2-capacity/ecs-ec2-capacity.tftest.hcl` | No public IPs, IMDSv2 required, tag propagation |
| `modules/k8s-ec2-infra` | `modules/k8s-ec2-infra/k8s-ec2-infra.tftest.hcl` | No public SSH, KMS key rotation, name_prefix, input validation |
| `modules/rds` | `modules/rds/rds.tftest.hcl` | Storage encryption, private by default, managed credentials, KMS rotation, name_prefix, tags |
| `modules/alb` | Not covered | Listener/ingress assertions pending |
| `modules/observability` | Not covered | Alarm dimensions and thresholds pending |

### Selector coverage
| Selector | Values covered |
| --- | --- |
| `platform` | `ecs`, `k8s_self_managed`, invalid value rejected, `eks` reserved guard |
| `ecs_capacity_mode` | `fargate`, `fargate_spot`, `ec2`, invalid value rejected |

## Remaining Gaps (Ranked)
1. `modules/alb` and `modules/observability` lack focused unit-level assertions (listener wiring, alarm thresholds/dimensions).
2. Tag coverage relies on representative resources (app SG, VPC, ECS/RDS/K8s resources); no plan-wide tag sweep.
3. No plan JSON assertions yet for “forbidden security posture” across all resources (e.g., 0.0.0.0/0 SSH sweep).

## How To Run
- `make test`

Expected behavior: Terraform tests run plan-only with mock providers across bootstrap, `tests/terraform`, environments, and selected modules. No state backend is required and no AWS credentials are used.
