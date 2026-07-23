terraform {
  backend "s3" {
    bucket  = "woneill-terraform-state"
    key     = "k8s-homelab/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}
