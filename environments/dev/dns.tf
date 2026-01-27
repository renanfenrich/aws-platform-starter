module "dns" {
  source = "../../modules/dns"

  name_prefix      = local.name_prefix
  tags             = local.tags
  enable_dns       = var.enable_dns
  hosted_zone_id   = var.dns_hosted_zone_id
  domain_name      = var.dns_domain_name
  record_name      = var.dns_record_name
  create_www_alias = var.dns_create_www_alias
  create_aaaa      = var.dns_create_aaaa
  target_type      = "alb"
  alb_dns_name     = module.alb.alb_dns_name
  alb_zone_id      = module.alb.alb_zone_id
}
