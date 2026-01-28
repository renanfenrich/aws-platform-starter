package kubernetes.policy

import data.kubernetes.lib as lib

required_labels := {
  "app.kubernetes.io/name",
  "app.kubernetes.io/instance",
  "app.kubernetes.io/part-of",
  "environment",
  "owner"
}

exception_key := "policy.aws-platform-starter/allow-missing-labels"

deny[msg] {
  lib.kind_requires_labels(input.kind)
  not lib.exception(input, exception_key)
  label := required_labels[_]
  not lib.has_label(input, label)
  msg := sprintf("%s/%s missing required label %s", [input.kind, lib.resource_name(input), label])
}
