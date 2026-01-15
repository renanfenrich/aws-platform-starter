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

resource "terraform_data" "github_oidc_role" {
  input = {
    enable_github_oidc_role = var.enable_github_oidc_role
    github_oidc_subjects    = var.github_oidc_subjects
    github_oidc_thumbprints = var.github_oidc_thumbprints
  }

  lifecycle {
    precondition {
      condition     = var.enable_github_oidc_role ? length(var.github_oidc_subjects) > 0 : true
      error_message = "enable_github_oidc_role requires at least one github_oidc_subjects entry."
    }

    precondition {
      condition     = var.enable_github_oidc_role ? length(var.github_oidc_thumbprints) > 0 : true
      error_message = "enable_github_oidc_role requires github_oidc_thumbprints to be set."
    }
  }
}
