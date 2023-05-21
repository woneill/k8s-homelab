variable "cluster_name" {
  type        = string
  description = "Unique cluster name"
}

variable "controllers" {
  type = list(object({
    name   = string
    mac    = string
    domain = string
  }))
  description = "List of nodes to use as controllers"
}

variable "workers" {
  type = list(object({
    name         = string
    mac          = string
    domain       = string
    install_disk = string
  }))
  description = "List of nodes to use as workers"
}

variable "k8s_domain_name" {
  type        = string
  description = "Control plane hostname"
}

variable "matchbox_http_endpoint" {
  type        = string
  description = "Matchbox HTTP read-only endpoint (e.g. http://matchbox.example.com:8080)"
}

variable "matchbox_rpc_endpoint" {
  type        = string
  description = "Matchbox gRPC API endpoint, without the protocol (e.g. matchbox.example.com:8081)"
}

variable "os_channel" {
  type        = string
  description = "Channel for a Flatcar Linux (flatcar-stable, flatcar-beta, flatcar-alpha)"
  default     = "flatcar-stable"
}

variable "os_version" {
  type        = string
  description = "Version of Flatcar Linux to PXE and install (e.g. 2079.5.1)"
}

variable "ssh_authorized_key" {
  type        = string
  description = "SSH key to use for authentication"
}
