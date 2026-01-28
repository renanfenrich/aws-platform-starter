package kubernetes.policy

import data.kubernetes.lib as lib

exception_key := "policy.aws-platform-starter/allow-missing-probes"

requires_probes {
  input.kind == "Deployment"
}

requires_probes {
  input.kind == "StatefulSet"
}

requires_probes {
  input.kind == "DaemonSet"
}

deny[msg] {
  requires_probes
  not lib.exception(input, exception_key)
  spec := lib.pod_spec(input)
  container := spec.containers[_]
  not container.livenessProbe
  msg := sprintf("%s/%s container %s must set livenessProbe", [input.kind, lib.resource_name(input), container.name])
}

deny[msg] {
  requires_probes
  not lib.exception(input, exception_key)
  spec := lib.pod_spec(input)
  container := spec.containers[_]
  not container.readinessProbe
  msg := sprintf("%s/%s container %s must set readinessProbe", [input.kind, lib.resource_name(input), container.name])
}
