package kubernetes.lib

import future.keywords.if

required_label_kinds := {
	"ConfigMap": true,
	"CronJob": true,
	"DaemonSet": true,
	"Deployment": true,
	"HorizontalPodAutoscaler": true,
	"Ingress": true,
	"Job": true,
	"Namespace": true,
	"NetworkPolicy": true,
	"PodDisruptionBudget": true,
	"Secret": true,
	"Service": true,
	"ServiceAccount": true,
	"StatefulSet": true,
}

tier_label_key := "platform.aws-platform-starter.io/tier"

namespace_tiers := {
	"apps": "apps",
	"demo": "apps",
	"argocd": "platform",
	"ingress": "platform",
	"cert-manager": "platform",
	"external-dns": "platform",
	"monitoring": "platform",
	"logging": "platform",
	"tracing": "platform",
}

workload_kinds := {
	"CronJob": true,
	"DaemonSet": true,
	"Deployment": true,
	"Job": true,
	"Pod": true,
	"StatefulSet": true,
}

kind_requires_labels(kind) if {
	required_label_kinds[kind]
}

has_tier_label(obj) if {
	metadata := object.get(obj, "metadata", {})
	labels := object.get(metadata, "labels", {})
	labels[tier_label_key] != ""
}

namespace_tier(obj) := tier if {
	metadata := object.get(obj, "metadata", {})
	labels := object.get(metadata, "labels", {})
	tier := labels[tier_label_key]
	tier != ""
}

namespace_tier(obj) := tier if {
	metadata := object.get(obj, "metadata", {})
	ns := object.get(metadata, "namespace", "")
	ns != ""
	tier := namespace_tiers[ns]
}

namespace_tier(obj) := "apps" if {
	metadata := object.get(obj, "metadata", {})
	ns := object.get(metadata, "namespace", "")
	ns != ""
	not namespace_tiers[ns]
	not has_tier_label(obj)
}

namespace_tier(obj) := "platform" if {
	metadata := object.get(obj, "metadata", {})
	ns := object.get(metadata, "namespace", "")
	ns == ""
	not has_tier_label(obj)
}

is_apps_tier(obj) if {
	namespace_tier(obj) == "apps"
}

is_workload(obj) if {
	workload_kinds[obj.kind]
}

resource_name(obj) := name if {
	name := obj.metadata.name
} else := "unknown"

pod_template(obj) := tmpl if {
	obj.kind == "Deployment"
	tmpl := obj.spec.template
}

pod_template(obj) := tmpl if {
	obj.kind == "StatefulSet"
	tmpl := obj.spec.template
}

pod_template(obj) := tmpl if {
	obj.kind == "DaemonSet"
	tmpl := obj.spec.template
}

pod_template(obj) := tmpl if {
	obj.kind == "Job"
	tmpl := obj.spec.template
}

pod_template(obj) := tmpl if {
	obj.kind == "CronJob"
	tmpl := obj.spec.jobTemplate.spec.template
}

pod_template(obj) := tmpl if {
	obj.kind == "Pod"
	tmpl := {"metadata": obj.metadata, "spec": obj.spec}
}

pod_spec(obj) := spec if {
	tmpl := pod_template(obj)
	spec := tmpl.spec
}

pod_metadata(obj) := metadata if {
	tmpl := pod_template(obj)
	metadata := object.get(tmpl, "metadata", {})
}

has_label(obj, key) if {
	labels := object.get(obj.metadata, "labels", {})
	labels[key] != ""
}

has_annotation(metadata, key) if {
	annotations := object.get(metadata, "annotations", {})
	annotations[key] == "true"
}

exception(obj, key) if {
	has_annotation(obj.metadata, key)
}

exception(obj, key) if {
	tmpl := pod_template(obj)
	has_annotation(object.get(tmpl, "metadata", {}), key)
}
