variable "domains" {
  description = "Domains to create hosted zones and email DNS records for"
  type        = list(string)
}

variable "mail_hostname" {
  description = "FQDN of the mail server (e.g. mail.example.com); A record created in its parent zone"
  type        = string
}

variable "mail_public_ip" {
  description = "Public IP of the mail server (used for the mail A record)"
  type        = string
}
