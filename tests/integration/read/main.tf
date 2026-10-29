# Reads data collection rules straight from Azure.
terraform {
  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.12"
    }
  }
}

variable "rule_ids" {
  type = map(string)
}

data "azapi_resource" "rule" {
  for_each = var.rule_ids

  type                   = "Microsoft.Insights/dataCollectionRules@2024-03-11"
  resource_id            = each.value
  response_export_values = ["properties.dataSources", "properties.destinations"]
}

output "destination_workspace_ids" {
  value = { for kind, rule in data.azapi_resource.rule : kind => [for destination in rule.output.properties.destinations.logAnalytics : lower(destination.workspaceResourceId)] }
}

output "extension_names" {
  value = { for kind, rule in data.azapi_resource.rule : kind => sort([for extension in try(rule.output.properties.dataSources.extensions, []) : extension.extensionName]) }
}

output "extension_settings" {
  value = { for kind, rule in data.azapi_resource.rule : kind => { for extension in try(rule.output.properties.dataSources.extensions, []) : extension.name => try(extension.extensionSettings, null) } }
}
