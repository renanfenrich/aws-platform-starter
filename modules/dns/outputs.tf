output "dns_enabled" {
  description = "Whether DNS record management is enabled."
  value       = var.enable_dns
}

output "dns_fqdn" {
  description = "Primary DNS name created by this module (null when no records are created)."
  value       = local.primary_fqdn
}

output "dns_records" {
  description = "Record names and types created by this module."
  value = concat(
    local.create_primary ? [{ name = local.fqdn, type = "A" }] : [],
    local.create_primary && local.create_aaaa ? [{ name = local.fqdn, type = "AAAA" }] : [],
    local.create_www ? [{ name = local.www_fqdn, type = "A" }] : [],
    local.create_www && local.create_aaaa ? [{ name = local.www_fqdn, type = "AAAA" }] : []
  )
}
