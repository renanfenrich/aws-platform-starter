package kubernetes.policy

import future.keywords.contains
import future.keywords.if
import data.kubernetes.lib as lib

services_exception_key := "policy.aws-platform-starter/allow-loadbalancer"

deny contains msg if {
	input.kind == "Service"
	input.spec.type == "LoadBalancer"
	not lib.exception(input, services_exception_key)
	msg := sprintf("Service/%s uses LoadBalancer without %s", [lib.resource_name(input), services_exception_key])
}
