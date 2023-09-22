module "mercury" {
  # The tag here maps to the Kubernetes version
  source = "github.com/poseidon/typhoon//bare-metal/flatcar-linux/kubernetes?ref=v1.28.2"
  # source = "github.com/poseidon/typhoon//bare-metal/flatcar-linux/kubernetes?ref=ae82c57eee1f70f9aeba6212d5e2315accfa8f03"

  # bare-metal
  cluster_name           = var.cluster_name
  matchbox_http_endpoint = var.matchbox_http_endpoint
  os_channel             = var.os_channel
  os_version             = var.os_version

  # configuration
  k8s_domain_name    = var.k8s_domain_name
  ssh_authorized_key = var.ssh_authorized_key
  snippets           = { for controller in var.controllers : controller.name => [file("./snippets/iscsi.yaml")] }

  # machines
  controllers = var.controllers

  # set to http only if you cannot chainload to iPXE firmware with https support
  download_protocol = "http"

  # Turn off pcie_aspm otherwise PXE booting won't work on e1000
  kernel_args = ["pcie_aspm=off"]
}

module "mercury_worker" {
  # The tag here maps to the Kubernetes version
  source = "github.com/poseidon/typhoon//bare-metal/flatcar-linux/kubernetes/worker?ref=v1.28.2"
  # source = "github.com/poseidon/typhoon//bare-metal/flatcar-linux/kubernetes/worker?ref=ae82c57eee1f70f9aeba6212d5e2315accfa8f03"

  for_each = { for worker in var.workers : worker.name => worker }
  # bare-metal
  cluster_name           = var.cluster_name
  matchbox_http_endpoint = var.matchbox_http_endpoint
  os_channel             = var.os_channel
  os_version             = var.os_version

  # configuration
  name               = each.key
  mac                = each.value.mac
  domain             = each.value.domain
  kubeconfig         = module.mercury.kubeconfig-admin
  ssh_authorized_key = var.ssh_authorized_key
  install_disk       = each.value.install_disk
  snippets           = [file("./snippets/iscsi.yaml")]

  # set to http only if you cannot chainload to iPXE firmware with https support
  download_protocol = "http"

  # Turn off pcie_aspm otherwise PXE booting won't work on e1000
  kernel_args = ["pcie_aspm=off"]
}
