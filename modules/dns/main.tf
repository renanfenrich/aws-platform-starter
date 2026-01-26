locals {
  record_label = trimspace(var.record_name)
  domain_label = trimspace(var.domain_name)
  is_apex      = local.record_label == ""
  fqdn         = local.is_apex ? local.domain_label : "${local.record_label}.${local.domain_label}"
  www_fqdn     = "www.${local.domain_label}"

  create_primary = var.enable_dns && (local.is_apex ? var.create_apex_alias : true)
  create_www     = var.enable_dns && local.is_apex && var.create_www_alias
  create_aaaa    = var.create_aaaa

  primary_fqdn = local.create_primary ? local.fqdn : local.create_www ? local.www_fqdn : null
}

resource "aws_route53_record" "primary_a" {
  count   = local.create_primary ? 1 : 0
  zone_id = var.hosted_zone_id
  name    = local.fqdn
  type    = "A"

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "primary_aaaa" {
  count   = local.create_primary && local.create_aaaa ? 1 : 0
  zone_id = var.hosted_zone_id
  name    = local.fqdn
  type    = "AAAA"

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "www_a" {
  count   = local.create_www ? 1 : 0
  zone_id = var.hosted_zone_id
  name    = local.www_fqdn
  type    = "A"

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "www_aaaa" {
  count   = local.create_www && local.create_aaaa ? 1 : 0
  zone_id = var.hosted_zone_id
  name    = local.www_fqdn
  type    = "AAAA"

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = false
  }
}
