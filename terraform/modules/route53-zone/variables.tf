variable "domains" {
  description = "Domains to create hosted zones and email DNS records for"
  type        = list(string)
}

variable "mail_public_ip" {
  description = "Public IPv4 of the mail server"
  type        = string
}

variable "mail_ipv6" {
  description = "Public IPv6 of the mail server"
  type        = string
}

variable "dkim_keys" {
  description = "Map of domain => full DKIM TXT record value; a wildcard *._domainkey record is created per entry"
  type        = map(string)
  default     = {}
}
