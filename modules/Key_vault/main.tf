data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "kv" {
  name                        = var.vault_name
  location                    = var.location
  resource_group_name         = var.resource_group_name
  tenant_id                   = var.tenant_id
  sku_name                    = "standard"
  soft_delete_retention_days  = 90
  purge_protection_enabled    = true
  enable_rbac_authorization   = true # Uses Azure RBAC for managing secret permissions

  tags = var.tags
}

output "vault_id" {
  value = azurerm_key_vault.kv.id
}

output "vault_uri" {
  value = azurerm_key_vault.kv.vault_uri
}