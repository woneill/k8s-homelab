provider "matchbox" {
  endpoint    = var.matchbox_rpc_endpoint
  client_cert = data.sops_file.client_cert.raw
  client_key  = data.sops_file.client_key.raw
  ca          = data.sops_file.ca.raw
}

provider "ct" {}
