data "sops_file" "ca" {
  source_file = "files/ca.crt"
  input_type  = "raw"
}

data "sops_file" "client_key" {
  source_file = "files/client.key"
  input_type  = "raw"
}

data "sops_file" "client_cert" {
  source_file = "files/client.crt"
  input_type  = "raw"
}
