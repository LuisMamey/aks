output "aks_cluster_name" {
  description = "Name of the deployed AKS cluster."
  value       = azurerm_kubernetes_cluster.aks.name
}

output "resource_group_name" {
  description = "Resource group containing the AKS cluster."
  value       = azurerm_resource_group.aks.name
}

output "get_credentials_command" {
  description = "Azure CLI command to configure kubectl for this cluster."
  value       = "az aks get-credentials --resource-group ${azurerm_resource_group.aks.name} --name ${azurerm_kubernetes_cluster.aks.name}"
}

output "acr_login_server" {
  description = "The URL of the private Azure Container Registry."
  value       = azurerm_container_registry.acr.login_server
}
