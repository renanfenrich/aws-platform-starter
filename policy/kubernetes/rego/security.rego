package kubernetes.security

import data.kubernetes.lib as lib

privileged_exception := "policy.aws-platform-starter/allow-privileged"
host_namespace_exception := "policy.aws-platform-starter/allow-host-namespace"
run_as_root_exception := "policy.aws-platform-starter/allow-run-as-root"
capabilities_exception := "policy.aws-platform-starter/allow-capabilities"

run_as_non_root(spec, container) if {
	spec.securityContext.runAsNonRoot == true
}

run_as_non_root(spec, container) if {
	container.securityContext.runAsNonRoot == true
}

drops_all(container) if {
	container.securityContext.capabilities.drop[_] == "ALL"
}

deny contains msg if {
	lib.is_workload(input)
	not lib.exception(input, privileged_exception)
	spec := lib.pod_spec(input)
	container := spec.containers[_]
	container.securityContext.privileged == true
	msg := sprintf("%s/%s container %s is privileged", [input.kind, lib.resource_name(input), container.name])
}

deny contains msg if {
	lib.is_workload(input)
	not lib.exception(input, host_namespace_exception)
	spec := lib.pod_spec(input)
	spec.hostNetwork == true
	msg := sprintf("%s/%s uses hostNetwork", [input.kind, lib.resource_name(input)])
}

deny contains msg if {
	lib.is_workload(input)
	not lib.exception(input, host_namespace_exception)
	spec := lib.pod_spec(input)
	spec.hostPID == true
	msg := sprintf("%s/%s uses hostPID", [input.kind, lib.resource_name(input)])
}

deny contains msg if {
	lib.is_workload(input)
	not lib.exception(input, host_namespace_exception)
	spec := lib.pod_spec(input)
	spec.hostIPC == true
	msg := sprintf("%s/%s uses hostIPC", [input.kind, lib.resource_name(input)])
}

deny contains msg if {
	lib.is_workload(input)
	not lib.exception(input, run_as_root_exception)
	spec := lib.pod_spec(input)
	container := spec.containers[_]
	not run_as_non_root(spec, container)
	msg := sprintf("%s/%s container %s must runAsNonRoot", [input.kind, lib.resource_name(input), container.name])
}

deny contains msg if {
	lib.is_workload(input)
	not lib.exception(input, capabilities_exception)
	spec := lib.pod_spec(input)
	container := spec.containers[_]
	not drops_all(container)
	msg := sprintf("%s/%s container %s must drop ALL capabilities", [input.kind, lib.resource_name(input), container.name])
}
