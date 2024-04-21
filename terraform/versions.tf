terraform {
  required_providers {
    ct = {
      source  = "poseidon/ct"
      version = "0.13.0"
    }
    matchbox = {
      source  = "poseidon/matchbox"
      version = "0.5.4"
    }
    sops = {
      source  = "carlpett/sops"
      version = "1.0.0"
    }
  }
  required_version = "1.8.1"
}
