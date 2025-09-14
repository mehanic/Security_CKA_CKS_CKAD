locals {
  cn  = var.domain
  org = var.org
}

# Root private key
resource "tls_private_key" "root" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P384"
}

# Root certificate
resource "tls_self_signed_cert" "root" {
  key_algorithm     = "ECDSA"
  private_key_pem   = tls_private_key.root.private_key_pem
  is_ca_certificate = true

  subject {
    common_name  = local.cn
    organization = local.org
  }

  validity_period_hours = var.root_validity_hours

  allowed_uses = ["cert_signing"]
}

# Intermediate key
resource "tls_private_key" "intermediate" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P384"
}

resource "tls_cert_request" "intermediate" {
  key_algorithm   = "ECDSA"
  private_key_pem = tls_private_key.intermediate.private_key_pem
  subject {
    common_name = "*.${local.cn}"
  }
}

resource "tls_locally_signed_cert" "intermediate" {
  cert_request_pem   = tls_cert_request.intermediate.cert_request_pem
  ca_key_algorithm   = "ECDSA"
  ca_private_key_pem = tls_private_key.root.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.root.cert_pem
  is_ca_certificate  = true

  validity_period_hours = var.intermediate_validity_hours
  allowed_uses          = ["cert_signing"]
}

# Child key
resource "tls_private_key" "child" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P384"
}

resource "tls_cert_request" "child" {
  key_algorithm   = "ECDSA"
  private_key_pem = tls_private_key.child.private_key_pem
  dns_names       = var.child_dns_names

  subject {
    common_name = join(",", var.child_dns_names)
  }
}

resource "tls_locally_signed_cert" "child" {
  cert_request_pem   = tls_cert_request.child.cert_request_pem
  ca_key_algorithm   = "ECDSA"
  ca_private_key_pem = tls_private_key.intermediate.private_key_pem
  ca_cert_pem        = tls_locally_signed_cert.intermediate.cert_pem

  validity_period_hours = var.child_validity_hours

  allowed_uses = ["server_auth"]
}

