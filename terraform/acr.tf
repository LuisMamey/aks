resource "azurerm_container_registry" "acr" {
  #checkov:skip=CKV_AZURE_165:Accepted risk — see docs/adr/0003-acr-tier-and-security-scope.md
  #checkov:skip=CKV_AZURE_233:Accepted risk — see docs/adr/0003-acr-tier-and-security-scope.md
  #checkov:skip=CKV_AZURE_139:Accepted risk — see docs/adr/0003-acr-tier-and-security-scope.md
  #checkov:skip=CKV_AZURE_237:Accepted risk — see docs/adr/0003-acr-tier-and-security-scope.md
  #checkov:skip=CKV_AZURE_167:Accepted risk — see docs/adr/0003-acr-tier-and-security-scope.md
  #checkov:skip=CKV_AZURE_164:Accepted risk — see docs/adr/0003-acr-tier-and-security-scope.md
  #checkov:skip=CKV_AZURE_163:Accepted risk — see docs/adr/0003-acr-tier-and-security-scope.md
  #checkov:skip=CKV_AZURE_166:Accepted risk — see docs/adr/0003-acr-tier-and-security-scope.md
  name                = "acr${replace(var.project_name, "-", "")}${var.environment}"
  resource_group_name = azurerm_resource_group.aks.name
  location            = azurerm_resource_group.aks.location
  sku                 = "Basic"
  admin_enabled       = false
  tags                = local.common_tags
}

resource "azurerm_role_assignment" "aks_acr_pull" {
  principal_id                     = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
  role_definition_name             = "AcrPull"
  scope                            = azurerm_container_registry.acr.id
  skip_service_principal_aad_check = true
}
