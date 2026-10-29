# Reads a data collection rule's data sources and data flows straight from Azure.
terraform {
  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.12"
    }
  }
}

variable "rule_id" {
  type = string
}

data "azapi_resource" "rule" {
  type                   = "Microsoft.Insights/dataCollectionRules@2024-03-11"
  resource_id            = var.rule_id
  response_export_values = ["properties.dataSources", "properties.dataFlows", "properties.description"]
}

output "data_flows" {
  value = data.azapi_resource.rule.output.properties.dataFlows
}

output "data_source_kinds" {
  # Kinds Azure reports with at least one entry.
  value = sort([for kind, sources in data.azapi_resource.rule.output.properties.dataSources : kind if try(length(sources), 0) > 0])
}

output "description" {
  value = try(data.azapi_resource.rule.output.properties.description, null)
}

output "extension_settings" {
  value = { for extension in try(data.azapi_resource.rule.output.properties.dataSources.extensions, []) : extension.name => try(extension.extensionSettings, null) }
}
