package kubernetes.security

import data.kubernetes.lib as lib

plaintext_exception := "policy.aws-platform-starter/allow-plaintext-secret"
encrypted_marker := "policy.aws-platform-starter/secret-encrypted"

deny[msg] {
  input.kind == "Secret"
  not lib.exception(input, plaintext_exception)
  not lib.exception(input, encrypted_marker)
  input.data
  msg := sprintf("Secret/%s includes data and lacks encrypted marker", [lib.resource_name(input)])
}

deny[msg] {
  input.kind == "Secret"
  not lib.exception(input, plaintext_exception)
  not lib.exception(input, encrypted_marker)
  input.stringData
  msg := sprintf("Secret/%s includes stringData and lacks encrypted marker", [lib.resource_name(input)])
}
