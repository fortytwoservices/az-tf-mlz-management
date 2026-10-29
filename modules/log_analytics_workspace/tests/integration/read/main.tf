# Reads a workspace's settings straight from Azure.
terraform {
  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.12"
    }
  }
}

variable "workspace_id" {
  type = string
}

data "azapi_resource" "workspace" {
  type        = "Microsoft.OperationalInsights/workspaces@2025-07-01"
  resource_id = var.workspace_id
  response_export_values = [
    "properties.customerId",
    "properties.features.disableLocalAuth",
    "properties.features.enableLogAccessUsingOnlyResourcePermissions",
    "properties.publicNetworkAccessForIngestion",
    "properties.publicNetworkAccessForQuery",
    "properties.retentionInDays",
    "properties.workspaceCapping.dailyQuotaGb",
  ]
}

output "customer_id" {
  value = data.azapi_resource.workspace.output.properties.customerId
}

output "daily_quota_gb" {
  value = data.azapi_resource.workspace.output.properties.workspaceCapping.dailyQuotaGb
}

output "local_authentication_disabled" {
  value = data.azapi_resource.workspace.output.properties.features.disableLocalAuth
}

output "public_network_access" {
  value = [data.azapi_resource.workspace.output.properties.publicNetworkAccessForIngestion, data.azapi_resource.workspace.output.properties.publicNetworkAccessForQuery]
}

output "resource_permissions_enabled" {
  value = data.azapi_resource.workspace.output.properties.features.enableLogAccessUsingOnlyResourcePermissions
}

output "retention_in_days" {
  value = data.azapi_resource.workspace.output.properties.retentionInDays
}
