variable "domain" {
  description = "Base domain for the PKI (e.g., example.com)"
  type        = string
}

variable "org" {
  description = "Organization name"
  type        = string
}

variable "root_validity_hours" {
  description = "Root CA validity (hours)"
  type        = number
  default     = 87600 # ~10 years
}

variable "intermediate_validity_hours" {
  description = "Intermediate CA validity (hours)"
  type        = number
  default     = 8760 # ~1 year
}

variable "child_validity_hours" {
  description = "Child cert validity (hours)"
  type        = number
  default     = 2160 # ~3 months
}

variable "child_dns_names" {
  description = "List of DNS names for the child certificate"
  type        = list(string)
  default     = []
}

