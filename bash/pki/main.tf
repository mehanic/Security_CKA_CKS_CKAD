module "pki" {
  source = "./certs/"

  domain                  = "rulz.xyz"
  org                     = "Rulz Corp."
  child_dns_names         = ["child.rulz.xyz"]
  root_validity_hours     = 87600
  intermediate_validity_hours = 8760
  child_validity_hours    = 2160
}

resource "local_file" "child_cert" {
  filename = "child.crt.pem"
  content  = module.pki.full_chain
}

resource "local_file" "child_key" {
  filename = "child.key.pem"
  content  = module.pki.child_key
}

