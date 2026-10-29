# Real Azure, no mocks: ARM_SUBSCRIPTION_ID=<test subscription> terraform test -test-directory=tests/integration
# Proves what mocks cannot: Azure accepts every data source kind with the bodies sent; removing a data
# source kind, a transformation, the description and one key of an extension's settings reaches Azure
# under the rule's lock.

run "setup" {
  module {
    source = "./tests/integration/setup"
  }
}

run "create" {
  variables {
    name        = "dcr-mlz-mgmt-it-${run.setup.suffix}"
    parent_id   = run.setup.resource_group_id
    location    = run.setup.location
    description = "Integration test"
    data_sources = {
      performance_counters = {
        perf = { streams = ["Microsoft-Perf"], sampling_frequency_in_seconds = 60, counter_specifiers = ["\\Processor(_Total)\\% Processor Time"] }
      }
      windows_event_logs = {
        events = { streams = ["Microsoft-Event"], x_path_queries = ["System!*[System[(Level=1 or Level=2)]]"] }
      }
      syslog = {
        syslog = { streams = ["Microsoft-Syslog"], facility_names = ["auth", "daemon"], log_levels = ["Error", "Critical"] }
      }
      extensions = {
        ct-linux = {
          extension_name     = "ChangeTracking-Linux"
          streams            = ["Microsoft-ConfigurationChange", "Microsoft-ConfigurationChangeV2", "Microsoft-ConfigurationData"]
          extension_settings = jsonencode({ enableFiles = true, enableSoftware = true, softwareSettings = { softwareCollectionFrequency = 300 } })
        }
      }
    }
    log_analytics_destinations = {
      workspace = { workspace_resource_id = run.setup.workspace_id }
    }
    data_flows = {
      ct     = { streams = ["Microsoft-ConfigurationChange", "Microsoft-ConfigurationChangeV2", "Microsoft-ConfigurationData"], destinations = ["workspace"] }
      events = { streams = ["Microsoft-Event"], destinations = ["workspace"], transform_kql = "source | where EventLevel <= 2" }
      perf   = { streams = ["Microsoft-Perf"], destinations = ["workspace"] }
      syslog = { streams = ["Microsoft-Syslog"], destinations = ["workspace"] }
    }
    lock = { kind = "CanNotDelete" }
    diagnostic_settings = {
      errors = {
        workspace_resource_id = run.setup.workspace_id
        logs                  = [{ category = "LogErrors" }]
        metrics               = [{ category = "AllMetrics" }]
      }
    }
  }

  assert {
    condition     = output.lock_resource_id != null && length(output.diagnostic_setting_resource_ids) == 1
    error_message = "The lock and the diagnostic setting should be created."
  }
}

run "created_in_azure" {
  module {
    source = "./tests/integration/read"
  }

  variables {
    rule_id = run.create.resource_id
  }

  assert {
    condition     = jsonencode(output.data_source_kinds) == jsonencode(["extensions", "performanceCounters", "syslog", "windowsEventLogs"])
    error_message = "Azure should report all four data source kinds."
  }
  assert {
    condition     = output.extension_settings["ct-linux"].softwareSettings.softwareCollectionFrequency == 300 && output.extension_settings["ct-linux"].enableSoftware == true
    error_message = "Azure should report the extension settings sent."
  }
  assert {
    condition     = length(output.data_flows) == 4 && output.description == "Integration test"
    error_message = "Azure should report four data flows and the description."
  }
}

run "remove_under_lock" {
  # Syslog, the Windows event logs, the transformation, the description and one settings key go, under
  # the lock.
  variables {
    name      = "dcr-mlz-mgmt-it-${run.setup.suffix}"
    parent_id = run.setup.resource_group_id
    location  = run.setup.location
    data_sources = {
      performance_counters = {
        perf = { streams = ["Microsoft-Perf"], sampling_frequency_in_seconds = 60, counter_specifiers = ["\\Processor(_Total)\\% Processor Time"] }
      }
      extensions = {
        ct-linux = {
          extension_name     = "ChangeTracking-Linux"
          streams            = ["Microsoft-ConfigurationChange", "Microsoft-ConfigurationChangeV2", "Microsoft-ConfigurationData"]
          extension_settings = jsonencode({ enableFiles = true, softwareSettings = { softwareCollectionFrequency = 300 } })
        }
      }
    }
    log_analytics_destinations = {
      workspace = { workspace_resource_id = run.setup.workspace_id }
    }
    data_flows = {
      ct   = { streams = ["Microsoft-ConfigurationChange", "Microsoft-ConfigurationChangeV2", "Microsoft-ConfigurationData"], destinations = ["workspace"] }
      perf = { streams = ["Microsoft-Perf"], destinations = ["workspace"] }
    }
    lock = { kind = "CanNotDelete" }
  }

  assert {
    condition     = output.resource_id == run.create.resource_id && output.lock_resource_id != null && length(output.diagnostic_setting_resource_ids) == 0
    error_message = "The rule should be updated in place, the diagnostic setting gone and the lock back."
  }
}

run "removed_in_azure" {
  module {
    source = "./tests/integration/read"
  }

  variables {
    rule_id = run.remove_under_lock.resource_id
  }

  assert {
    condition     = jsonencode(output.data_source_kinds) == jsonencode(["extensions", "performanceCounters"])
    error_message = "Azure should no longer report syslog or Windows event logs."
  }
  assert {
    condition     = !contains(keys(output.extension_settings["ct-linux"]), "enableSoftware")
    error_message = "The removed extension settings key should be gone in Azure."
  }
  assert {
    condition     = length(output.data_flows) == 2 && alltrue([for flow in output.data_flows : try(flow.transformKql, null) == null]) && output.description == null
    error_message = "Azure should report two data flows without a transformation, and no description."
  }
}
