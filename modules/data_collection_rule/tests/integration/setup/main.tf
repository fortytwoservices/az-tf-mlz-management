# A resource group and a Log Analytics workspace for one integration test run, and the identity running
# the test.
terraform {
  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.12"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

data "azapi_client_config" "current" {}

resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

resource "azapi_resource" "resource_group" {
  type      = "Microsoft.Resources/resourceGroups@2024-11-01"
  name      = "rg-mlz-mgmt-dcr-${random_string.suffix.result}"
  parent_id = "/subscriptions/${data.azapi_client_config.current.subscription_id}"
  location  = "swedencentral"
}

resource "azapi_resource" "workspace" {
  type      = "Microsoft.OperationalInsights/workspaces@2025-07-01"
  name      = "law-mlz-mgmt-dcr-${random_string.suffix.result}"
  parent_id = azapi_resource.resource_group.id
  location  = azapi_resource.resource_group.location
  body = {
    properties = { sku = { name = "PerGB2018" } }
  }
  delete_query_parameters = { force = ["true"] }
  response_export_values  = []
}

# Change tracking's tables come with its solution, a minute or so after it is created.
resource "azapi_resource" "change_tracking_solution" {
  type      = "Microsoft.OperationsManagement/solutions@2015-11-01-preview"
  name      = "ChangeTracking(${azapi_resource.workspace.name})"
  parent_id = azapi_resource.resource_group.id
  location  = azapi_resource.resource_group.location
  body = {
    plan       = { name = "ChangeTracking(${azapi_resource.workspace.name})", product = "OMSGallery/ChangeTracking", publisher = "Microsoft", promotionCode = "" }
    properties = { workspaceResourceId = azapi_resource.workspace.id }
  }
  response_export_values = []
}

output "location" {
  value = azapi_resource.resource_group.location
}

output "object_id" {
  value = data.azapi_client_config.current.object_id
}

output "resource_group_id" {
  value = azapi_resource.resource_group.id
}

output "suffix" {
  value = random_string.suffix.result
}

output "subscription_id" {
  value = data.azapi_client_config.current.subscription_id
}

output "workspace_id" {
  value      = azapi_resource.workspace.id
  depends_on = [azapi_resource.change_tracking_solution]
}
