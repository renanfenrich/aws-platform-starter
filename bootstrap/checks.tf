resource "terraform_data" "acm_dns_validation" {
  input = {
    acm_domain_name = var.acm_domain_name
    acm_zone_id     = var.acm_zone_id
  }

  lifecycle {
    precondition {
      condition = (
        length(trimspace(var.acm_domain_name)) == 0 && length(trimspace(var.acm_zone_id)) == 0
        ) || (
        length(trimspace(var.acm_domain_name)) > 0 && length(trimspace(var.acm_zone_id)) > 0
      )
      error_message = "acm_domain_name and acm_zone_id must be set together to enable ACM DNS validation."
    }
  }
}
