# Real Azure, no mocks: ARM_SUBSCRIPTION_ID=<test subscription> terraform test -test-directory=tests/integration
# Proves what mocks cannot: Azure accepts the three ALZ rules as sent (schema validation on) and they
# send to the workspace; their settings change in place under the lock; a rule and the identity are
# removed under their locks.

run "setup" {
  module {
    source = "./tests/integration/setup"
  }
}

run "create" {
  variables {
    name                          = "law-mlz-mgmt-it-${run.setup.suffix}"
    parent_id                     = run.setup.resource_group_id
    location                      = run.setup.location
    permanently_delete_on_destroy = true
    data_collection_rules = {
      change_tracking = { name = "dcr-mlz-mgmt-it-ct-${run.setup.suffix}" }
      vm_insights     = { name = "dcr-mlz-mgmt-it-vmi-${run.setup.suffix}" }
      defender_sql    = { name = "dcr-mlz-mgmt-it-sql-${run.setup.suffix}" }
    }
    user_assigned_identity = { name = "id-mlz-mgmt-it-ama-${run.setup.suffix}" }
    lock                   = { kind = "CanNotDelete" }
    diagnostic_settings = {
      self = {
        workspace_resource_id = "/subscriptions/${run.setup.subscription_id}/resourceGroups/rg-mlz-mgmt-it-${run.setup.suffix}/providers/Microsoft.OperationalInsights/workspaces/law-mlz-mgmt-it-${run.setup.suffix}"
        logs                  = [{ category_group = "allLogs" }]
        metrics               = [{ category = "AllMetrics" }]
      }
    }
  }

  assert {
    condition     = jsonencode(keys(output.data_collection_rule_resource_ids)) == jsonencode(["change_tracking", "defender_sql", "vm_insights"])
    error_message = "The three rules should be created."
  }
  assert {
    condition     = can(regex("^[0-9a-f-]{36}$", output.user_assigned_identity.principal_id))
    error_message = "The identity should be created."
  }
}

run "rules_in_azure" {
  module {
    source = "./tests/integration/read"
  }

  variables {
    rule_ids = run.create.data_collection_rule_resource_ids
  }

  assert {
    condition     = alltrue([for kind, ids in output.destination_workspace_ids : jsonencode(ids) == jsonencode([lower(run.create.resource_id)])])
    error_message = "Every rule should send to the workspace."
  }
  assert {
    condition     = jsonencode(output.extension_names) == jsonencode({ change_tracking = ["ChangeTracking-Linux", "ChangeTracking-Windows"], defender_sql = ["MicrosoftDefenderForSQL"], vm_insights = [] })
    error_message = "Azure should report the rules' extension data sources, and none on VM insights."
  }
  assert {
    condition     = length(output.extension_settings.change_tracking["CTDataSource-Windows"].registrySettings.registryInfo) == 17
    error_message = "Azure should report the 17 registry keys of Windows change tracking."
  }
}

run "update_under_lock" {
  variables {
    name                          = "law-mlz-mgmt-it-${run.setup.suffix}"
    parent_id                     = run.setup.resource_group_id
    location                      = run.setup.location
    permanently_delete_on_destroy = true
    data_collection_rules = {
      change_tracking = { name = "dcr-mlz-mgmt-it-ct-${run.setup.suffix}" }
      vm_insights     = { name = "dcr-mlz-mgmt-it-vmi-${run.setup.suffix}", processes_and_dependencies_enabled = true }
      defender_sql    = { name = "dcr-mlz-mgmt-it-sql-${run.setup.suffix}", sql_queries_collection_enabled = true }
    }
    user_assigned_identity = { name = "id-mlz-mgmt-it-ama-${run.setup.suffix}" }
    lock                   = { kind = "CanNotDelete" }
  }

  assert {
    condition     = output.data_collection_rule_resource_ids == run.create.data_collection_rule_resource_ids
    error_message = "The rules should be updated in place."
  }
}

run "updated_in_azure" {
  module {
    source = "./tests/integration/read"
  }

  variables {
    rule_ids = run.update_under_lock.data_collection_rule_resource_ids
  }

  assert {
    condition     = jsonencode(output.extension_names.vm_insights) == jsonencode(["DependencyAgent"])
    error_message = "VM insights should collect processes and dependencies through the Dependency agent."
  }
  assert {
    condition     = output.extension_settings.defender_sql.MicrosoftDefenderForSQL.enableCollectionOfSqlQueriesForSecurityResearch == true
    error_message = "Defender for SQL should collect SQL queries."
  }
}

run "remove_rule_and_identity_under_lock" {
  variables {
    name                          = "law-mlz-mgmt-it-${run.setup.suffix}"
    parent_id                     = run.setup.resource_group_id
    location                      = run.setup.location
    permanently_delete_on_destroy = true
    data_collection_rules = {
      change_tracking = { name = "dcr-mlz-mgmt-it-ct-${run.setup.suffix}" }
      vm_insights     = { name = "dcr-mlz-mgmt-it-vmi-${run.setup.suffix}" }
    }
    lock = { kind = "CanNotDelete" }
  }

  assert {
    condition     = jsonencode(keys(output.data_collection_rule_resource_ids)) == jsonencode(["change_tracking", "vm_insights"]) && output.user_assigned_identity == null
    error_message = "The Defender for SQL rule and the identity should be gone."
  }
}

run "processes_and_dependencies_off_in_azure" {
  module {
    source = "./tests/integration/read"
  }

  variables {
    rule_ids = run.remove_rule_and_identity_under_lock.data_collection_rule_resource_ids
  }

  assert {
    condition     = length(output.extension_names.vm_insights) == 0
    error_message = "Turning processes and dependencies off should remove the Dependency agent's data source in Azure."
  }
}
