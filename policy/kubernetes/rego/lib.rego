package kubernetes.lib

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
  "StatefulSet": true
}

workload_kinds := {
  "CronJob": true,
  "DaemonSet": true,
  "Deployment": true,
  "Job": true,
  "Pod": true,
  "StatefulSet": true
}

kind_requires_labels(kind) {
  required_label_kinds[kind]
}

is_workload(obj) {
  workload_kinds[obj.kind]
}

resource_name(obj) = name {
  name := obj.metadata.name
} else = "unknown" {
  true
}

pod_template(obj) = tmpl {
  obj.kind == "Deployment"
  tmpl := obj.spec.template
}

pod_template(obj) = tmpl {
  obj.kind == "StatefulSet"
  tmpl := obj.spec.template
}

pod_template(obj) = tmpl {
  obj.kind == "DaemonSet"
  tmpl := obj.spec.template
}

pod_template(obj) = tmpl {
  obj.kind == "Job"
  tmpl := obj.spec.template
}

pod_template(obj) = tmpl {
  obj.kind == "CronJob"
  tmpl := obj.spec.jobTemplate.spec.template
}

pod_template(obj) = tmpl {
  obj.kind == "Pod"
  tmpl := {"metadata": obj.metadata, "spec": obj.spec}
}

pod_spec(obj) = spec {
  tmpl := pod_template(obj)
  spec := tmpl.spec
}

pod_metadata(obj) = metadata {
  tmpl := pod_template(obj)
  metadata := object.get(tmpl, "metadata", {})
}

has_label(obj, key) {
  labels := object.get(obj.metadata, "labels", {})
  labels[key] != ""
}

has_annotation(metadata, key) {
  annotations := object.get(metadata, "annotations", {})
  annotations[key] == "true"
}

exception(obj, key) {
  has_annotation(obj.metadata, key)
}

exception(obj, key) {
  tmpl := pod_template(obj)
  has_annotation(object.get(tmpl, "metadata", {}), key)
}
