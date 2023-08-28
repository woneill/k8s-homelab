# terraform-k8s-homelab

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | 1.5.6 |
| <a name="requirement_ct"></a> [ct](#requirement\_ct) | 0.12.0 |
| <a name="requirement_matchbox"></a> [matchbox](#requirement\_matchbox) | 0.5.2 |
| <a name="requirement_sops"></a> [sops](#requirement\_sops) | 0.7.2 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_sops"></a> [sops](#provider\_sops) | 0.7.2 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_mercury"></a> [mercury](#module\_mercury) | github.com/poseidon/typhoon//bare-metal/flatcar-linux/kubernetes | v1.27.4 |
| <a name="module_mercury_worker"></a> [mercury\_worker](#module\_mercury\_worker) | github.com/poseidon/typhoon//bare-metal/flatcar-linux/kubernetes/worker | v1.27.4 |

## Resources

| Name | Type |
|------|------|
| [sops_file.ca](https://registry.terraform.io/providers/carlpett/sops/0.7.2/docs/data-sources/file) | data source |
| [sops_file.client_cert](https://registry.terraform.io/providers/carlpett/sops/0.7.2/docs/data-sources/file) | data source |
| [sops_file.client_key](https://registry.terraform.io/providers/carlpett/sops/0.7.2/docs/data-sources/file) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Unique cluster name | `string` | n/a | yes |
| <a name="input_controllers"></a> [controllers](#input\_controllers) | List of nodes to use as controllers | <pre>list(object({<br>    name   = string<br>    mac    = string<br>    domain = string<br>  }))</pre> | n/a | yes |
| <a name="input_k8s_domain_name"></a> [k8s\_domain\_name](#input\_k8s\_domain\_name) | Control plane hostname | `string` | n/a | yes |
| <a name="input_matchbox_http_endpoint"></a> [matchbox\_http\_endpoint](#input\_matchbox\_http\_endpoint) | Matchbox HTTP read-only endpoint (e.g. http://matchbox.example.com:8080) | `string` | n/a | yes |
| <a name="input_matchbox_rpc_endpoint"></a> [matchbox\_rpc\_endpoint](#input\_matchbox\_rpc\_endpoint) | Matchbox gRPC API endpoint, without the protocol (e.g. matchbox.example.com:8081) | `string` | n/a | yes |
| <a name="input_os_version"></a> [os\_version](#input\_os\_version) | Version of Flatcar Linux to PXE and install (e.g. 2079.5.1) | `string` | n/a | yes |
| <a name="input_ssh_authorized_key"></a> [ssh\_authorized\_key](#input\_ssh\_authorized\_key) | SSH key to use for authentication | `string` | n/a | yes |
| <a name="input_workers"></a> [workers](#input\_workers) | List of nodes to use as workers | <pre>list(object({<br>    name         = string<br>    mac          = string<br>    domain       = string<br>    install_disk = string<br>  }))</pre> | n/a | yes |
| <a name="input_os_channel"></a> [os\_channel](#input\_os\_channel) | Channel for a Flatcar Linux (flatcar-stable, flatcar-beta, flatcar-alpha) | `string` | `"flatcar-stable"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_kubeconfig_admin"></a> [kubeconfig\_admin](#output\_kubeconfig\_admin) | Generate kubeconfig file |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
