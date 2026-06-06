output "zone_ids" {
  description = "Map of domain => zone ID"
  value       = { for domain, zone in aws_route53_zone.this : domain => zone.zone_id }
}

output "name_servers" {
  description = "Map of domain => name servers (verify with registrar if zones were recreated)"
  value       = { for domain, zone in aws_route53_zone.this : domain => zone.name_servers }
}
