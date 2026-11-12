resource "azurerm_resource_group" "aks" {
  name     = "rg-${local.name_prefix}"
  location = var.location
  tags     = local.common_tags
}
