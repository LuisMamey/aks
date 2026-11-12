resource "azurerm_user_assigned_identity" "app" {
  name                = "id-${local.name_prefix}-app"
  resource_group_name = azurerm_resource_group.aks.name
  location            = azurerm_resource_group.aks.location
  tags                = local.common_tags
}

resource "azurerm_role_assignment" "app_storage_reader" {
  scope                = "/subscriptions/${var.subscription_id}/resourceGroups/rg-tfstate/providers/Microsoft.Storage/storageAccounts/sttfstateluismamey01"
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = azurerm_user_assigned_identity.app.principal_id
}

resource "azurerm_federated_identity_credential" "app" {
  name                      = "fic-${local.name_prefix}-app"
  user_assigned_identity_id = azurerm_user_assigned_identity.app.id
  audience                  = ["api://AzureADTokenExchange"]
  issuer                    = azurerm_kubernetes_cluster.aks.oidc_issuer_url
  subject                   = "system:serviceaccount:default:workload-identity-sa"
}
