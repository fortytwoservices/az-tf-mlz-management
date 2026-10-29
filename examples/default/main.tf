# Subscription from ARM_SUBSCRIPTION_ID or the Azure CLI; credentials from the Azure CLI or OIDC.
provider "azapi" {}

locals {
  location = "swedencentral"
  tags     = { example = "default" }
}

data "azapi_client_config" "current" {}

# Workspace names stay reserved for 14 days after a delete, so every run gets new names.
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

resource "azapi_resource" "resource_group" {
  type      = "Microsoft.Resources/resourceGroups@2024-11-01"
  name      = "rg-mlz-mgmt-example-${random_string.suffix.result}"
  parent_id = "/subscriptions/${data.azapi_client_config.current.subscription_id}"
  location  = local.location

  response_export_values = []
  tags                   = local.tags
}

module "management" {
  source = "../../"

  name      = "law-mlz-mgmt-example-${random_string.suffix.result}"
  parent_id = azapi_resource.resource_group.id
  location  = local.location
  data_collection_rules = {
    change_tracking = { name = "dcr-mlz-mgmt-example-ct-${random_string.suffix.result}" }
    vm_insights     = { name = "dcr-mlz-mgmt-example-vmi-${random_string.suffix.result}", processes_and_dependencies_enabled = true }
    defender_sql    = { name = "dcr-mlz-mgmt-example-sql-${random_string.suffix.result}" }
  }
  user_assigned_identity = { name = "id-mlz-mgmt-example-ama-${random_string.suffix.result}" }
  lock                   = { kind = "CanNotDelete" }
  # The workspace's own audit logs and metrics, sent to itself.
  diagnostic_settings = {
    self = {
      workspace_resource_id = "${azapi_resource.resource_group.id}/providers/Microsoft.OperationalInsights/workspaces/law-mlz-mgmt-example-${random_string.suffix.result}"
      logs                  = [{ category_group = "allLogs" }]
      metrics               = [{ category = "AllMetrics" }]
    }
  }
  tags = local.tags
}
