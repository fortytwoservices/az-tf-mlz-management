# Validates a pricing body against the AzAPI provider's embedded schema, which azapi_resource checks during
# plan and azapi_update_resource does not (azapi 2.12.0, probed 2026-10-29). Plan only, with mocks.
terraform {
  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.12"
    }
  }
}

variable "body" {
  type        = any
  description = "The pricing body to validate."
}

resource "azapi_resource" "schema_check" {
  type      = "Microsoft.Security/pricings@2024-01-01"
  name      = "VirtualMachines"
  parent_id = "/subscriptions/00000000-0000-0000-0000-000000000000"
  body      = var.body
}
