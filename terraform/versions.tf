terraform {
  required_providers {
    authentik = {
      source  = "goauthentik/authentik"
      version = "2026.5.0"
    }
    sops = {
      source  = "carlpett/sops"
      version = "1.4.1"
    }
  }
  required_version = "1.15.8"
}
