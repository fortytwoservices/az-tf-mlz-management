mock_provider "azapi" {
  mock_resource "azapi_resource" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Insights/dataCollectionRules/dcr-test"
    }
  }
  mock_data "azapi_resource_list" {
    defaults = {
      output = {
        results = [
          {
            id        = "/subscriptions/00000000-0000-0000-0000-000000000000/providers/Microsoft.Authorization/roleDefinitions/acdd72a7-3385-48ef-bd42-f606fba81ae7"
            role_name = "Reader"
          }
        ]
      }
    }
  }
}
mock_provider "random" {}
mock_provider "time" {}

variables {
  location  = "swedencentral"
  name      = "dcr-test"
  parent_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test"
  data_sources = {
    performance_counters = {
      perf = {
        streams                       = ["Microsoft-Perf"]
        sampling_frequency_in_seconds = 60
        counter_specifiers            = ["\\Processor(_Total)\\% Processor Time"]
      }
    }
  }
  log_analytics_destinations = {
    workspace = { workspace_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.OperationalInsights/workspaces/law-test" }
  }
  data_flows = {
    perf = { streams = ["Microsoft-Perf"], destinations = ["workspace"] }
  }
}

run "defaults" {
  command = apply

  assert {
    condition     = azapi_resource.this.type == "Microsoft.Insights/dataCollectionRules@2024-03-11"
    error_message = "The rule should use the default resource type."
  }
  assert {
    condition     = azapi_resource.this.name == var.name && azapi_resource.this.parent_id == var.parent_id && azapi_resource.this.location == var.location
    error_message = "The rule should be created with name, parent_id and location."
  }
  assert {
    condition = jsonencode(azapi_resource.this.body) == jsonencode({
      properties = {
        description = null
        dataSources = {
          performanceCounters = [{
            name                       = "perf"
            streams                    = ["Microsoft-Perf"]
            samplingFrequencyInSeconds = 60
            counterSpecifiers          = ["\\Processor(_Total)\\% Processor Time"]
          }]
          windowsEventLogs = null
          syslog           = null
          extensions       = null
        }
        destinations = {
          logAnalytics = [{
            name                = "workspace"
            workspaceResourceId = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.OperationalInsights/workspaces/law-test"
          }]
        }
        dataFlows = [{
          streams      = ["Microsoft-Perf"]
          destinations = ["workspace"]
          transformKql = null
          outputStream = null
        }]
      }
    })
    error_message = "Every data source kind and optional property should be sent, null when unset."
  }
  assert {
    condition     = jsonencode(azapi_resource.this.sensitive_body_version) == jsonencode({ "properties.dataSources.extensions" = sha256(jsonencode([])) })
    error_message = "The extensions' version should be the hash of the (empty) extensions."
  }
  assert {
    condition     = azapi_resource.this.retry.error_message_regex == tolist(["InvalidOutputTable"]) && azapi_resource.this.retry.interval_seconds == 30 && azapi_resource.this.retry.max_interval_seconds == 300
    error_message = "Missing destination tables should be retried by default."
  }
  assert {
    condition     = azapi_resource.this.timeouts == null
    error_message = "timeouts should be unset by default."
  }
  assert {
    condition     = output.lock_resource_id == null && length(output.role_assignment_resource_ids) + length(output.diagnostic_setting_resource_ids) == 0
    error_message = "No lock, role assignment or diagnostic setting should be created by default."
  }
  assert {
    condition     = output.resource_id == azapi_resource.this.id && output.name == var.name
    error_message = "resource_id and name should come from the rule."
  }
}

run "every_data_source_kind" {
  command = apply

  variables {
    description = "Every kind"
    data_sources = {
      performance_counters = {
        perf = { streams = ["Microsoft-Perf"], sampling_frequency_in_seconds = 30, counter_specifiers = ["\\Memory\\Available Bytes"] }
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
          extension_settings = jsonencode({ enableFiles = true, fileSettings = { fileCollectionFrequency = 900 } })
        }
        dependency = {
          extension_name     = "DependencyAgent"
          streams            = ["Microsoft-ServiceMap"]
          input_data_sources = ["perf"]
        }
      }
    }
    data_flows = {
      a-perf   = { streams = ["Microsoft-Perf"], destinations = ["workspace"] }
      b-events = { streams = ["Microsoft-Event"], destinations = ["workspace"], transform_kql = "source | where EventLevel <= 2", output_stream = "Microsoft-Event" }
    }
  }

  assert {
    condition     = azapi_resource.this.body.properties.description == "Every kind"
    error_message = "description should be sent."
  }
  assert {
    condition     = azapi_resource.this.body.properties.dataSources.windowsEventLogs[0].xPathQueries[0] == "System!*[System[(Level=1 or Level=2)]]" && azapi_resource.this.body.properties.dataSources.syslog[0].facilityNames == tolist(["auth", "daemon"])
    error_message = "Windows event logs and syslog should map to their properties."
  }
  assert {
    condition     = [for e in azapi_resource.this.body.properties.dataSources.extensions : e.name] == ["ct-linux", "dependency"]
    error_message = "Extensions should be sent in key order, named by key."
  }
  assert {
    condition     = azapi_resource.this.body.properties.dataSources.extensions[0].extensionSettings.fileSettings.fileCollectionFrequency == 900 && azapi_resource.this.body.properties.dataSources.extensions[0].inputDataSources == null
    error_message = "Extension settings should be decoded from JSON; no input data sources should be sent as null."
  }
  assert {
    condition     = azapi_resource.this.body.properties.dataSources.extensions[1].extensionSettings == null && azapi_resource.this.body.properties.dataSources.extensions[1].inputDataSources == tolist(["perf"])
    error_message = "No extension settings should be sent as null; input data sources should be sent."
  }
  assert {
    condition     = azapi_resource.this.body.properties.dataFlows[1].transformKql == "source | where EventLevel <= 2" && azapi_resource.this.body.properties.dataFlows[1].outputStream == "Microsoft-Event"
    error_message = "Data flows should be sent in key order with their transformation."
  }
  assert {
    condition     = azapi_resource.this.sensitive_body_version["properties.dataSources.extensions"] != sha256(jsonencode([]))
    error_message = "The extensions' version should change with the extensions."
  }
}

run "interfaces" {
  command = apply

  variables {
    lock = { kind = "CanNotDelete" }
    role_assignments = {
      reader = {
        role_definition_id_or_name = "Reader"
        principal_id               = "55555555-5555-5555-5555-555555555555"
      }
    }
    diagnostic_settings = {
      errors = {
        workspace_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.OperationalInsights/workspaces/law-test"
        logs                  = [{ category = "LogErrors" }]
      }
    }
    tags = { environment = "test" }
  }

  # Their behaviour is tested in az-tf-mlz-interfaces; a test sees only its outputs.
  assert {
    condition     = output.lock_resource_id != null && keys(output.role_assignment_resource_ids) == ["reader"] && keys(output.diagnostic_setting_resource_ids) == ["errors"]
    error_message = "The lock, role assignments and diagnostic settings should be created through az-tf-mlz-interfaces."
  }
  assert {
    condition     = azapi_resource.this.tags == tomap({ environment = "test" })
    error_message = "tags should be set on the rule."
  }
}

run "azapi_settings_reach_every_resource" {
  command = apply

  # ignore_body_changes is write-only, so a test cannot read it back; which resource reads which slot is
  # left to review. The interface keys go to az-tf-mlz-interfaces, whose tests check them.
  variables {
    lock = { kind = "CanNotDelete" }
    resource_types = {
      insights_data_collection_rules = "Microsoft.Insights/dataCollectionRules@2023-03-11"
      authorization_locks            = "Microsoft.Authorization/locks@2016-09-01"
      authorization_role_assignments = "Microsoft.Authorization/roleAssignments@2020-04-01-preview"
      insights_diagnostic_settings   = "Microsoft.Insights/diagnosticSettings@2021-05-01-preview"
    }
    ignore_body_changes = {
      insights_data_collection_rules = ["properties.description"]
      authorization_locks            = ["properties.notes"]
      authorization_role_assignments = ["properties.description"]
      insights_diagnostic_settings   = ["properties.logs"]
    }
    retry = {
      error_message_regex = ["AnotherOperationInProgress"]
    }
    timeouts = {
      create = "15m"
    }
  }

  assert {
    condition     = azapi_resource.this.type == "Microsoft.Insights/dataCollectionRules@2023-03-11"
    error_message = "The resource_types override should reach the rule."
  }
  assert {
    condition     = azapi_resource.this.retry.error_message_regex == tolist(["AnotherOperationInProgress"]) && azapi_resource.this.timeouts.create == "15m"
    error_message = "retry and timeouts should reach the rule."
  }
}

run "invalid_parent_id" {
  command = plan

  variables {
    parent_id = "/subscriptions/00000000-0000-0000-0000-000000000000"
  }

  expect_failures = [var.parent_id]
}

run "no_data_flow" {
  command = plan

  variables {
    data_flows = {}
  }

  expect_failures = [var.data_flows]
}

run "data_flow_without_stream" {
  command = plan

  variables {
    data_flows = {
      perf = { streams = [], destinations = ["workspace"] }
    }
  }

  expect_failures = [var.data_flows]
}

run "data_flow_without_destination" {
  command = plan

  variables {
    data_flows = {
      perf = { streams = ["Microsoft-Perf"], destinations = [] }
    }
  }

  expect_failures = [var.data_flows]
}

run "data_flow_to_unknown_destination" {
  command = plan

  variables {
    data_flows = {
      perf = { streams = ["Microsoft-Perf"], destinations = ["elsewhere"] }
    }
  }

  expect_failures = [var.data_flows]
}

run "no_destination" {
  command = plan

  # The data flow validations that read log_analytics_destinations are not evaluated once it fails.
  variables {
    log_analytics_destinations = {}
  }

  expect_failures = [var.log_analytics_destinations]
}

run "invalid_workspace_resource_id" {
  command = plan

  variables {
    log_analytics_destinations = {
      workspace = { workspace_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test" }
    }
  }

  expect_failures = [var.log_analytics_destinations]
}

run "duplicate_data_source_name" {
  command = plan

  variables {
    data_sources = {
      performance_counters = {
        perf = { streams = ["Microsoft-Perf"], sampling_frequency_in_seconds = 60, counter_specifiers = ["\\Memory\\Available Bytes"] }
      }
      syslog = {
        perf = { streams = ["Microsoft-Syslog"], facility_names = ["*"], log_levels = ["*"] }
      }
    }
  }

  expect_failures = [var.data_sources]
}

run "invalid_extension_settings" {
  command = plan

  variables {
    data_sources = {
      extensions = {
        ct = { extension_name = "ChangeTracking-Linux", streams = ["Microsoft-ConfigurationChange"], extension_settings = "{not json" }
      }
    }
  }

  expect_failures = [var.data_sources]
}

run "invalid_sampling_frequency" {
  command = plan

  variables {
    data_sources = {
      performance_counters = {
        perf = { streams = ["Microsoft-Perf"], sampling_frequency_in_seconds = 0, counter_specifiers = ["\\Memory\\Available Bytes"] }
      }
    }
  }

  expect_failures = [var.data_sources]
}

run "invalid_lock_kind" {
  command = plan

  variables {
    lock = { kind = "Delete" }
  }

  expect_failures = [var.lock]
}
