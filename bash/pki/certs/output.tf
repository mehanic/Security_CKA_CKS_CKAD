output "root_ca_cert" {
  value = tls_self_signed_cert.root.cert_pem
}

output "intermediate_cert" {
  value = tls_locally_signed_cert.intermediate.cert_pem
}

output "child_cert" {
  value = tls_locally_signed_cert.child.cert_pem
}

output "child_key" {
  sensitive = true
  value     = tls_private_key.child.private_key_pem
}

output "full_chain" {
  value = join("", [
    tls_locally_signed_cert.child.cert_pem,
    tls_locally_signed_cert.intermediate.cert_pem,
    tls_self_signed_cert.root.cert_pem,
  ])
}

