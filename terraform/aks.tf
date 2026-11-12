resource "azurerm_kubernetes_cluster" "aks" {
  #checkov:skip=CKV_AZURE_170:Accepted risk — see docs/adr/0002-aks-security-scope.md
  #checkov:skip=CKV_AZURE_115:Accepted risk — see docs/adr/0002-aks-security-scope.md
  #checkov:skip=CKV_AZURE_6:Accepted risk — see docs/adr/0002-aks-security-scope.md
  #checkov:skip=CKV_AZURE_232:Accepted risk — see docs/adr/0002-aks-security-scope.md
  #checkov:skip=CKV_AZURE_141:Accepted risk — see docs/adr/0002-aks-security-scope.md
  #checkov:skip=CKV_AZURE_117:Accepted risk — see docs/adr/0002-aks-security-scope.md
  #checkov:skip=CKV_AZURE_227:Accepted risk — see docs/adr/0002-aks-security-scope.md
  name                      = "aks-${local.name_prefix}"
  location                  = azurerm_resource_group.aks.location
  resource_group_name       = azurerm_resource_group.aks.name
  dns_prefix                = local.name_prefix
  sku_tier                  = "Free"
  automatic_upgrade_channel = "patch"
  azure_policy_enabled      = true
  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  default_node_pool {
    name                        = "system"
    node_count                  = 1
    vm_size                     = "Standard_D2ds_v6"
    vnet_subnet_id              = azurerm_subnet.aks.id
    max_pods                    = 50
    os_disk_type                = "Ephemeral"
    os_disk_size_gb             = 30
    temporary_name_for_rotation = "sysrot"
  }

  identity {
    type = "SystemAssigned"
  }

  node_provisioning_profile {
    mode = "Manual"
  }

  network_profile {
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
    network_policy      = "azure"
    pod_cidr            = "192.168.0.0/16"
    service_cidr        = "10.20.0.0/16"
    dns_service_ip      = "10.20.0.10"
  }

  key_vault_secrets_provider {
    secret_rotation_enabled = true
  }

  oms_agent {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.aks.id
  }

  tags = local.common_tags
}
