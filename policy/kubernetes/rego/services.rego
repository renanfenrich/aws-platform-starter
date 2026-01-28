package kubernetes.policy

import data.kubernetes.lib as lib

exception_key := "policy.aws-platform-starter/allow-loadbalancer"

deny[msg] {
  input.kind == "Service"
  input.spec.type == "LoadBalancer"
  not lib.exception(input, exception_key)
  msg := sprintf("Service/%s uses LoadBalancer without %s", [lib.resource_name(input), exception_key])
}
