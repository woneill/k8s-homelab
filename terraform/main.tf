provider "authentik" {
  url   = data.sops_file.secrets.data["authentik_url"]
  token = data.sops_file.secrets.data["authentik_token"]
}

provider "sops" {}
