package kubernetes.policy

import data.kubernetes.lib as lib

probes_exception_key := "policy.aws-platform-starter/allow-missing-probes"

probe_required_kinds := {
	"DaemonSet": true,
	"Deployment": true,
	"StatefulSet": true,
}

requires_probes if {
	probe_required_kinds[input.kind]
}

deny contains msg if {
	requires_probes
	not lib.exception(input, probes_exception_key)
	spec := lib.pod_spec(input)
	container := spec.containers[_]
	not container.livenessProbe
	msg := sprintf("%s/%s container %s must set livenessProbe", [input.kind, lib.resource_name(input), container.name])
}

deny contains msg if {
	requires_probes
	not lib.exception(input, probes_exception_key)
	spec := lib.pod_spec(input)
	container := spec.containers[_]
	not container.readinessProbe
	msg := sprintf("%s/%s container %s must set readinessProbe", [input.kind, lib.resource_name(input), container.name])
}
