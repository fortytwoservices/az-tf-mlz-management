# Subscription from ARM_SUBSCRIPTION_ID or the Azure CLI; credentials from the Azure CLI or OIDC.
provider "azapi" {}

locals {
  location = "swedencentral"
  tags     = { example = "data-collection-rule" }
}

data "azapi_client_config" "current" {}

resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

resource "azapi_resource" "resource_group" {
  type      = "Microsoft.Resources/resourceGroups@2024-11-01"
  name      = "rg-mlz-mgmt-example-dcr-${random_string.suffix.result}"
  parent_id = "/subscriptions/${data.azapi_client_config.current.subscription_id}"
  location  = local.location

  response_export_values = []
  tags                   = local.tags
}

module "log_analytics_workspace" {
  source = "../../modules/log_analytics_workspace"

  name                          = "law-mlz-mgmt-example-dcr-${random_string.suffix.result}"
  parent_id                     = azapi_resource.resource_group.id
  location                      = local.location
  permanently_delete_on_destroy = true # an example, rebuilt from scratch on every run
  tags                          = local.tags
}

# A workload's own rule: Windows errors and warnings, Linux authentication logs and two counters, with a
# transformation that keeps only errors from the Windows events. Its error logs go to the workspace.
module "data_collection_rule" {
  source = "../../modules/data_collection_rule"

  name        = "dcr-mlz-mgmt-example-${random_string.suffix.result}"
  parent_id   = azapi_resource.resource_group.id
  location    = local.location
  description = "Windows events, syslog and performance counters."
  data_sources = {
    performance_counters = {
      basic-counters = {
        streams                       = ["Microsoft-Perf"]
        sampling_frequency_in_seconds = 60
        counter_specifiers            = ["\\Processor(_Total)\\% Processor Time", "\\Memory\\Available Bytes"]
      }
    }
    windows_event_logs = {
      system-errors = {
        streams        = ["Microsoft-Event"]
        x_path_queries = ["System!*[System[(Level=1 or Level=2 or Level=3)]]"]
      }
    }
    syslog = {
      auth = {
        streams        = ["Microsoft-Syslog"]
        facility_names = ["auth", "authpriv"]
        log_levels     = ["Warning", "Error", "Critical", "Alert", "Emergency"]
      }
    }
  }
  log_analytics_destinations = {
    workspace = { workspace_resource_id = module.log_analytics_workspace.resource_id }
  }
  data_flows = {
    events = { streams = ["Microsoft-Event"], destinations = ["workspace"], transform_kql = "source | where EventLevel <= 2" }
    perf   = { streams = ["Microsoft-Perf"], destinations = ["workspace"] }
    syslog = { streams = ["Microsoft-Syslog"], destinations = ["workspace"] }
  }
  diagnostic_settings = {
    errors = {
      workspace_resource_id = module.log_analytics_workspace.resource_id
      logs                  = [{ category = "LogErrors" }]
    }
  }
  tags = local.tags
}
