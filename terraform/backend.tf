terraform {
  cloud {
    organization = "monkeyfaith"

    workspaces {
      name = "k8s_homelab"
    }
  }
}
