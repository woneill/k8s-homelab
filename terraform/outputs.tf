output "kubeconfig_admin" {
  description = "Generate kubeconfig file"
  value       = module.mercury.kubeconfig-admin
  sensitive   = true
}
