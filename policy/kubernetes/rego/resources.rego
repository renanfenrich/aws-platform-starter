package kubernetes.policy

import data.kubernetes.lib as lib

exception_key := "policy.aws-platform-starter/allow-missing-resources"

deny[msg] {
  lib.is_workload(input)
  not lib.exception(input, exception_key)
  spec := lib.pod_spec(input)
  container := spec.containers[_]
  not has_requests_and_limits(container)
  msg := sprintf("%s/%s container %s must set cpu/memory requests and limits", [input.kind, lib.resource_name(input), container.name])
}

deny[msg] {
  lib.is_workload(input)
  not lib.exception(input, exception_key)
  spec := lib.pod_spec(input)
  init := spec.initContainers[_]
  not has_requests_and_limits(init)
  msg := sprintf("%s/%s initContainer %s must set cpu/memory requests and limits", [input.kind, lib.resource_name(input), init.name])
}

has_requests_and_limits(container) {
  container.resources.requests.cpu
  container.resources.requests.memory
  container.resources.limits.cpu
  container.resources.limits.memory
}
