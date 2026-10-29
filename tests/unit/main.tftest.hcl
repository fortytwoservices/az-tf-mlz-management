mock_provider "azapi" {
  mock_resource "azapi_resource" {
    defaults = {
      # One ID for every resource: a workspace ID, which the rules' destinations must be.
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.OperationalInsights/workspaces/law-test"
      output = {
        properties = {
          customerId  = "77777777-7777-7777-7777-777777777777"
          clientId    = "22222222-2222-2222-2222-222222222222"
          principalId = "33333333-3333-3333-3333-333333333333"
          tenantId    = "44444444-4444-4444-4444-444444444444"
        }
      }
    }
  }
  mock_resource "azapi_update_resource" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/providers/Microsoft.Security/pricings/VirtualMachines"
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
  name      = "law-test"
  parent_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test"
}

run "defaults" {
  command = apply

  assert {
    condition     = module.log_analytics_workspace.name == var.name && output.name == var.name
    error_message = "The workspace should be created with the module's name."
  }
  assert {
    condition     = output.resource_id == module.log_analytics_workspace.resource_id && output.workspace_id == "77777777-7777-7777-7777-777777777777"
    error_message = "resource_id and workspace_id should come from the workspace."
  }
  assert {
    condition     = length(module.data_collection_rule) == 0 && length(output.data_collection_rule_resource_ids) == 0
    error_message = "No data collection rule should be created by default."
  }
  assert {
    condition     = length(module.user_assigned_identity) == 0 && output.user_assigned_identity == null
    error_message = "No identity should be created by default."
  }
  assert {
    condition     = output.sentinel_onboarding_resource_id == null && length(module.defender_plan) == 0 && length(output.defender_plan_resource_ids) == 0
    error_message = "Neither Sentinel nor a Defender plan should be set by default."
  }
  assert {
    condition     = module.log_analytics_workspace.lock_resource_id == null && length(module.log_analytics_workspace.role_assignment_resource_ids) + length(module.log_analytics_workspace.diagnostic_setting_resource_ids) + length(module.log_analytics_workspace.solution_resource_ids) == 0
    error_message = "No lock, role assignment, diagnostic setting or solution should be created by default."
  }
}

run "every_resource" {
  command = apply

  variables {
    data_collection_rules = {
      change_tracking = { name = "dcr-change-tracking" }
      vm_insights     = { name = "dcr-vm-insights" }
      defender_sql    = { name = "dcr-defender-sql" }
    }
    user_assigned_identity = { name = "id-ama" }
  }

  assert {
    condition     = keys(module.data_collection_rule) == ["change_tracking", "defender_sql", "vm_insights"]
    error_message = "One rule should be created per named kind."
  }
  assert {
    condition     = module.data_collection_rule["change_tracking"].name == "dcr-change-tracking" && module.data_collection_rule["vm_insights"].name == "dcr-vm-insights" && module.data_collection_rule["defender_sql"].name == "dcr-defender-sql"
    error_message = "Each rule should take its name."
  }
  assert {
    condition     = keys(output.data_collection_rule_resource_ids) == ["change_tracking", "defender_sql", "vm_insights"]
    error_message = "Rule IDs should be output by kind."
  }
  assert {
    condition     = output.user_assigned_identity.name == "id-ama" && output.user_assigned_identity.principal_id == "33333333-3333-3333-3333-333333333333" && output.user_assigned_identity.client_id == "22222222-2222-2222-2222-222222222222"
    error_message = "The identity's name, principal ID and client ID should be output."
  }
  assert {
    condition     = output.user_assigned_identity.resource_id == module.user_assigned_identity[0].resource_id
    error_message = "The identity's resource ID should be output."
  }
  assert {
    condition     = jsonencode(keys(module.log_analytics_workspace.solution_resource_ids)) == jsonencode(["ChangeTracking", "SQLAdvancedThreatProtection", "SQLVulnerabilityAssessment"])
    error_message = "The workspace should get the solutions whose tables change tracking and Defender for SQL send to."
  }
}

run "one_rule" {
  command = apply

  variables {
    data_collection_rules = {
      vm_insights = { name = "dcr-vm-insights" }
    }
  }

  assert {
    condition     = keys(module.data_collection_rule) == ["vm_insights"]
    error_message = "Only the named rule should be created."
  }
  assert {
    condition     = length(module.log_analytics_workspace.solution_resource_ids) == 0
    error_message = "VM insights should need no solution."
  }
}

run "change_tracking_solution_only" {
  command = apply

  variables {
    data_collection_rules = {
      change_tracking = { name = "dcr-change-tracking" }
    }
  }

  assert {
    condition     = jsonencode(keys(module.log_analytics_workspace.solution_resource_ids)) == jsonencode(["ChangeTracking"])
    error_message = "Change tracking alone should need only its solution."
  }
}

run "change_tracking_body" {
  command = plan

  assert {
    condition     = local.data_collection_rules.change_tracking.destination == "Microsoft-CT-Dest" && keys(local.data_collection_rules.change_tracking.data_flows) == ["change_tracking"]
    error_message = "Change tracking should send its streams to its one destination."
  }
  assert {
    condition     = keys(local.data_collection_rules.change_tracking.data_sources.extensions) == ["CTDataSource-Linux", "CTDataSource-Windows"]
    error_message = "Change tracking should have the Windows and Linux extension data sources."
  }
  assert {
    condition = alltrue([
      for source in local.data_collection_rules.change_tracking.data_sources.extensions :
      source.streams == ["Microsoft-ConfigurationChange", "Microsoft-ConfigurationChangeV2", "Microsoft-ConfigurationData"]
    ])
    error_message = "Both change tracking data sources should send the three configuration streams."
  }
  assert {
    condition     = [for entry in jsondecode(local.data_collection_rules.change_tracking.data_sources.extensions["CTDataSource-Windows"].extension_settings).registrySettings.registryInfo : entry.name] == [for i in range(1, 18) : "Registry_${i}"]
    error_message = "Windows change tracking should watch the 17 recommended registry keys, Registry_1 to Registry_17."
  }
  assert {
    condition     = jsondecode(local.data_collection_rules.change_tracking.data_sources.extensions["CTDataSource-Windows"].extension_settings).registrySettings.registryInfo[16].keyName == "HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Winlogon\\Notify"
    error_message = "The registry keys should keep AVM's order and single backslashes."
  }
  assert {
    condition     = jsondecode(local.data_collection_rules.change_tracking.data_sources.extensions["CTDataSource-Linux"].extension_settings).fileSettings.fileInfo[0].destinationPath == "/etc/.*.conf"
    error_message = "Linux change tracking should watch /etc/*.conf files."
  }
}

run "vm_insights_body_default" {
  command = plan

  variables {
    data_collection_rules = {
      vm_insights = { name = "dcr-vm-insights" }
    }
  }

  assert {
    condition     = local.data_collection_rules.vm_insights.data_sources.performance_counters.VMInsightsPerfCounters.counter_specifiers == ["\\VmInsights\\DetailedMetrics"]
    error_message = "VM insights should collect its detailed metrics counter set."
  }
  assert {
    condition     = length(local.data_collection_rules.vm_insights.data_sources.extensions) == 0 && keys(local.data_collection_rules.vm_insights.data_flows) == ["insights_metrics"]
    error_message = "VM insights should collect no processes and dependencies by default."
  }
}

run "vm_insights_processes_and_dependencies" {
  command = plan

  variables {
    data_collection_rules = {
      vm_insights = { name = "dcr-vm-insights", processes_and_dependencies_enabled = true }
    }
  }

  assert {
    condition     = local.data_collection_rules.vm_insights.data_sources.extensions.DependencyAgentDataSource.extension_name == "DependencyAgent"
    error_message = "Processes and dependencies should come from the Dependency agent's extension data source."
  }
  assert {
    condition     = keys(local.data_collection_rules.vm_insights.data_flows) == ["insights_metrics", "service_map"] && local.data_collection_rules.vm_insights.data_flows.service_map.streams == ["Microsoft-ServiceMap"]
    error_message = "The service map stream should get its own data flow."
  }
}

run "defender_sql_body" {
  command = plan

  variables {
    data_collection_rules = {
      defender_sql = { name = "dcr-defender-sql", sql_queries_collection_enabled = true }
    }
  }

  assert {
    condition     = jsondecode(local.data_collection_rules.defender_sql.data_sources.extensions.MicrosoftDefenderForSQL.extension_settings).enableCollectionOfSqlQueriesForSecurityResearch == true
    error_message = "sql_queries_collection_enabled should reach the extension settings."
  }
  assert {
    condition     = length(local.data_collection_rules.defender_sql.data_flows.defender_sql.streams) == 6
    error_message = "Defender for SQL should send its six streams."
  }
}

run "defender_sql_queries_off_by_default" {
  command = plan

  variables {
    data_collection_rules = {
      defender_sql = { name = "dcr-defender-sql" }
    }
  }

  assert {
    condition     = jsondecode(local.data_collection_rules.defender_sql.data_sources.extensions.MicrosoftDefenderForSQL.extension_settings).enableCollectionOfSqlQueriesForSecurityResearch == false
    error_message = "SQL queries should not be collected by default."
  }
}

run "sentinel_onboarding" {
  command = apply

  variables {
    sentinel_onboarding = { customer_managed_key_enabled = true }
  }

  assert {
    condition     = output.sentinel_onboarding_resource_id != null && output.sentinel_onboarding_resource_id == module.log_analytics_workspace.sentinel_onboarding_resource_id
    error_message = "Sentinel should be onboarded through the workspace submodule, and its ID output."
  }
}

run "defender_plans" {
  command = apply

  variables {
    defender_plans = {
      management-servers = {
        subscription_id = "/subscriptions/00000000-0000-0000-0000-000000000000"
        plan            = "VirtualMachines"
        sub_plan        = "P2"
        extensions      = { AgentlessVmScanning = { enabled = true } }
      }
      connectivity-cspm = {
        subscription_id = "/subscriptions/11111111-1111-1111-1111-111111111111"
        plan            = "CloudPosture"
      }
      management-storage-off = {
        subscription_id = "/subscriptions/00000000-0000-0000-0000-000000000000"
        plan            = "StorageAccounts"
        tier            = "Free"
      }
    }
  }

  assert {
    condition     = jsonencode(keys(module.defender_plan)) == jsonencode(["connectivity-cspm", "management-servers", "management-storage-off"])
    error_message = "One plan should be set per entry."
  }
  assert {
    condition     = module.defender_plan["management-servers"].name == "VirtualMachines" && module.defender_plan["connectivity-cspm"].name == "CloudPosture"
    error_message = "Each entry should set its plan."
  }
  assert {
    condition     = jsonencode(keys(output.defender_plan_resource_ids)) == jsonencode(["connectivity-cspm", "management-servers", "management-storage-off"])
    error_message = "Plan IDs should be output by key."
  }
}

run "duplicate_defender_plan" {
  command = plan

  variables {
    defender_plans = {
      one = { subscription_id = "/subscriptions/00000000-0000-0000-0000-000000000000", plan = "KeyVaults" }
      two = { subscription_id = "/subscriptions/00000000-0000-0000-0000-000000000000", plan = "keyvaults" }
    }
  }

  expect_failures = [var.defender_plans]
}

run "interfaces" {
  command = apply

  variables {
    data_collection_rules = {
      change_tracking = { name = "dcr-change-tracking" }
      vm_insights     = { name = "dcr-vm-insights" }
    }
    user_assigned_identity = { name = "id-ama" }
    lock                   = { kind = "CanNotDelete" }
    role_assignments = {
      reader = {
        role_definition_id_or_name = "Reader"
        principal_id               = "55555555-5555-5555-5555-555555555555"
      }
    }
    diagnostic_settings = {
      self = {
        workspace_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.OperationalInsights/workspaces/law-central"
        logs                  = [{ category_group = "allLogs" }]
      }
    }
  }

  assert {
    condition     = module.log_analytics_workspace.lock_resource_id != null && alltrue([for rule in module.data_collection_rule : rule.lock_resource_id != null]) && module.user_assigned_identity[0].lock_resource_id != null
    error_message = "The lock should go on the workspace, every rule and the identity."
  }
  assert {
    condition     = keys(module.log_analytics_workspace.role_assignment_resource_ids) == ["reader"] && keys(module.log_analytics_workspace.diagnostic_setting_resource_ids) == ["self"]
    error_message = "Role assignments and diagnostic settings should go on the workspace."
  }
  assert {
    condition     = alltrue([for rule in module.data_collection_rule : length(rule.role_assignment_resource_ids) + length(rule.diagnostic_setting_resource_ids) == 0]) && length(module.user_assigned_identity[0].role_assignment_resource_ids) == 0
    error_message = "Role assignments and diagnostic settings should not go on the rules or the identity."
  }
}

run "azapi_settings_are_accepted" {
  command = apply

  # The slots reach the submodules, whose tests check their own wiring; a test here sees only the
  # submodules' outputs, so which slot reaches which resource is left to review.
  variables {
    data_collection_rules  = { change_tracking = { name = "dcr-change-tracking" } }
    user_assigned_identity = { name = "id-ama" }
    resource_types = {
      operationalinsights_workspaces           = { operationalinsights_workspaces = "Microsoft.OperationalInsights/workspaces@2025-02-01" }
      insights_data_collection_rules           = { insights_data_collection_rules = "Microsoft.Insights/dataCollectionRules@2023-03-11" }
      managedidentity_user_assigned_identities = { managedidentity_user_assigned_identities = "Microsoft.ManagedIdentity/userAssignedIdentities@2025-05-31-preview" }
      security_pricings                        = { security_pricings = "Microsoft.Security/pricings@2023-01-01" }
    }
    defender_plans = {
      kv = { subscription_id = "/subscriptions/00000000-0000-0000-0000-000000000000", plan = "KeyVaults" }
    }
    ignore_body_changes = {
      operationalinsights_workspaces           = { operationalinsights_workspaces = ["properties.retentionInDays"] }
      insights_data_collection_rules           = { insights_data_collection_rules = ["properties.description"] }
      managedidentity_user_assigned_identities = { managedidentity_user_assigned_identities = ["properties.isolationScope"] }
    }
    retry    = { error_message_regex = ["AnotherOperationInProgress"] }
    timeouts = { create = "15m" }
  }

  assert {
    condition     = length(module.data_collection_rule) == 1 && length(module.user_assigned_identity) == 1 && length(module.defender_plan) == 1
    error_message = "The overrides should be accepted by every submodule."
  }
}

run "invalid_name" {
  command = plan

  variables {
    name = "law_test"
  }

  expect_failures = [var.name]
}

run "invalid_parent_id" {
  command = plan

  variables {
    parent_id = "/subscriptions/00000000-0000-0000-0000-000000000000"
  }

  expect_failures = [var.parent_id]
}

run "invalid_retention" {
  command = plan

  variables {
    retention_in_days = 7
  }

  expect_failures = [var.retention_in_days]
}

run "invalid_daily_quota" {
  command = plan

  variables {
    daily_quota_gb = -1
  }

  expect_failures = [var.daily_quota_gb]
}

run "invalid_public_network_access" {
  command = plan

  variables {
    public_network_access_for_query = "SecuredByPerimeter"
  }

  expect_failures = [var.public_network_access_for_query]
}

run "invalid_lock_kind" {
  command = plan

  variables {
    lock = { kind = "Delete" }
  }

  expect_failures = [var.lock]
}
