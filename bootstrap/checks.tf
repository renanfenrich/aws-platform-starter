check "acm_dns_validation_inputs" {
  assert {
    condition = (
      length(trimspace(var.acm_domain_name)) == 0 && length(trimspace(var.acm_zone_id)) == 0
    ) || (
      length(trimspace(var.acm_domain_name)) > 0 && length(trimspace(var.acm_zone_id)) > 0
    )
    error_message = "acm_domain_name and acm_zone_id must be set together to enable ACM DNS validation."
  }
}
