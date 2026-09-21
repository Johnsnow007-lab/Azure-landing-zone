module "rg_networking" {
  source   = "./modules/resource_group"
  name     = "rg-hub-networking-dev"
  location = "UK South"
  tags = {
    Environment = "Development"
    CostCentre  = "IT-101"
    Owner       = "CloudEngineer"
    Project     = "LandingZone"
  }
}
module "hub_vnet" {
  source              = "./modules/vnet"
  vnet_name           = "vnet-hub-uksouth"
  location            = module.rg_networking.location
  resource_group_name = module.rg_networking.name
  address_space       = ["10.0.0.0/16"]

  subnets = {
    snet-management = "10.0.1.0/24"
    snet-shared     = "10.0.2.0/24"
  }

  tags = {
    Environment = "Development"
    CostCentre  = "IT-101"
    Owner       = "CloudEngineer"
    Project     = "LandingZone"
  }
}
# 1. Create Resource Group for Spoke Workloads
module "rg_spoke" {
  source   = "./modules/resource_group"
  name     = "rg-spoke-workload-dev"
  location = "UK South"
  tags = {
    Environment = "Development"
    CostCentre  = "IT-101"
    Owner       = "CloudEngineer"
    Project     = "LandingZone"
  }
}

# 2. Create Spoke VNet with Tier Subnets
module "spoke_vnet" {
  source              = "./modules/vnet"
  vnet_name           = "vnet-spoke-uksouth"
  location            = module.rg_spoke.location
  resource_group_name = module.rg_spoke.name
  address_space       = ["10.1.0.0/16"]

  subnets = {
    snet-web  = "10.1.1.0/24"
    snet-app  = "10.1.2.0/24"
    snet-data = "10.1.3.0/24"
  }

  tags = {
    Environment = "Development"
    CostCentre  = "IT-101"
    Owner       = "CloudEngineer"
    Project     = "LandingZone"
  }
}
# Peer Hub to Spoke
resource "azurerm_virtual_network_peering" "hub_to_spoke" {
  name                      = "peer-hub-to-spoke"
  resource_group_name       = module.rg_networking.name
  virtual_network_name      = "vnet-hub-uksouth"
  remote_virtual_network_id = module.spoke_vnet.vnet_id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}

# Peer Spoke to Hub
resource "azurerm_virtual_network_peering" "spoke_to_hub" {
  name                      = "peer-spoke-to-hub"
  resource_group_name       = module.rg_spoke.name
  virtual_network_name      = "vnet-spoke-uksouth"
  remote_virtual_network_id = module.hub_vnet.vnet_id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}
# Get current subscription context
data "azurerm_subscription" "current" {}

# Assign Built-in Azure Policy: Require a tag on resources
resource "azurerm_subscription_policy_assignment" "require_tag_env" {
  name                 = "enforce-tag-environment"
  display_name         = "Require 'Environment' tag on all resources"
  subscription_id      = data.azurerm_subscription.current.id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/871b6d14-10aa-478d-b590-94f262ecfa99" # Built-in definition for requiring a tag

  # Pass parameters to the policy specifying the tag name we want to enforce
  parameters = jsonencode({
    "tagName" = {
      "value" = "Environment"
    }
  })
}
# Fetch Azure Tenant ID automatically
data "azurerm_client_config" "current" {}

module "key_vault" {
  source              = "./modules/key_vault"
  vault_name          = "kv-shared-uksouth-01"
  location            = module.rg_networking.location
  resource_group_name = module.rg_networking.name
  tenant_id           = data.azurerm_client_config.current.tenant_id

  tags = {
    Environment = "Development"
    CostCentre  = "IT-101"
    Owner       = "CloudEngineer"
    Project     = "LandingZone"
  }
}
# 1. Assign Contributor Role to Engineering (simulated via current client or principal)

# Get the Subscription ID scope
# Assign Reader Role to Finance Team (using a placeholder or current user object ID for testing)
resource "azurerm_role_assignment" "finance_reader" {
  scope                = data.azurerm_subscription.current.id
  role_definition_name = "Reader"
  principal_id         = data.azurerm_client_config.current.object_id # In production, replace with Finance Azure AD Group ID
}

# Assign Contributor Role to Engineering Team
resource "azurerm_role_assignment" "engineering_contributor" {
  scope                = module.rg_spoke.id # Scoped specifically to the Spoke workload resource group
  role_definition_name = "Contributor"
  principal_id         = data.azurerm_client_config.current.object_id # In production, replace with Engineering Azure AD Group ID
}
resource "azurerm_log_analytics_workspace" "law" {
  name                = "law-shared-uksouth-01"
  location            = module.rg_networking.location
  resource_group_name = module.rg_networking.name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = {
    Environment = "Development"
    CostCentre  = "IT-101"
    Owner       = "CloudEngineer"
    Project     = "LandingZone"
  }
}
resource "azurerm_consumption_budget_subscription" "subscription_budget" {
  name            = "budget-development-monthly"
  subscription_id = data.azurerm_subscription.current.id

  amount     = 1000 # Monthly budget limit
  time_grain = "Monthly"

  time_period {
    start_date = "2026-01-01T00:00:00Z"
    end_date   = "2027-12-31T23:59:59Z"
  }

  notification {
    enabled        = true
    threshold      = 80
    operator       = "EqualTo"
    contact_emails = ["admin@yourdomain.com"]
  }

  notification {
    enabled        = true
    threshold      = 100
    operator       = "EqualTo"
    contact_emails = ["admin@yourdomain.com", "finance@yourdomain.com"]
  }
}