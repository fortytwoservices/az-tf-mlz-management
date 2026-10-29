# Real Azure, no mocks: ARM_SUBSCRIPTION_ID=<test subscription> terraform test -test-directory=tests/integration
# Proves what mocks cannot: every setting reaches Azure and changing it back does too, under the lock;
# diagnostic settings, role assignments and a solution are removed under the lock; solutions follow a
# renamed workspace; a permanently deleted workspace
# releases its name (a soft-deleted one would be recovered with its old workspace ID).

run "setup" {
  module {
    source = "./tests/integration/setup"
  }
}

run "create" {
  variables {
    name                                = "law-mlz-mgmt-it-${run.setup.suffix}"
    parent_id                           = run.setup.resource_group_id
    location                            = run.setup.location
    permanently_delete_on_destroy       = true
    daily_quota_gb                      = 0.5
    local_authentication_enabled        = true
    public_network_access_for_ingestion = "Disabled"
    public_network_access_for_query     = "Disabled"
    resource_permissions_enabled        = false
    retention_in_days                   = 31
    solutions                           = ["ChangeTracking", "SQLAdvancedThreatProtection"]
    lock                                = { kind = "CanNotDelete" }
    role_assignments = {
      reader = { role_definition_id_or_name = "Reader", principal_id = run.setup.object_id }
    }
    diagnostic_settings = {
      self = {
        workspace_resource_id = "/subscriptions/${run.setup.subscription_id}/resourceGroups/rg-mlz-mgmt-law-${run.setup.suffix}/providers/Microsoft.OperationalInsights/workspaces/law-mlz-mgmt-it-${run.setup.suffix}"
        logs                  = [{ category_group = "allLogs" }]
        metrics               = [{ category = "AllMetrics" }]
      }
    }
  }

  assert {
    condition     = can(regex("^[0-9a-f-]{36}$", output.workspace_id))
    error_message = "workspace_id should be read back from Azure."
  }
  assert {
    condition     = output.lock_resource_id != null && length(output.role_assignment_resource_ids) == 1 && length(output.diagnostic_setting_resource_ids) == 1
    error_message = "The lock, the role assignment and the diagnostic setting should be created."
  }
  assert {
    condition     = keys(output.solution_resource_ids) == ["ChangeTracking", "SQLAdvancedThreatProtection"]
    error_message = "Both solutions should be created."
  }
}

run "settings_in_azure" {
  module {
    source = "./tests/integration/read"
  }

  variables {
    workspace_id = run.create.resource_id
  }

  assert {
    condition     = output.daily_quota_gb == 0.5 && output.retention_in_days == 31
    error_message = "Azure should report the daily cap and retention set by create."
  }
  assert {
    condition     = output.local_authentication_disabled == false && output.resource_permissions_enabled == false
    error_message = "Azure should report local authentication on and resource permissions off."
  }
  assert {
    condition     = output.public_network_access == ["Disabled", "Disabled"]
    error_message = "Azure should report public network access disabled for ingestion and query."
  }
}

run "reset_under_lock" {
  # Every setting back to its default, the role assignment, diagnostic setting and a solution removed, the
  # lock kept.
  variables {
    name                          = "law-mlz-mgmt-it-${run.setup.suffix}"
    parent_id                     = run.setup.resource_group_id
    location                      = run.setup.location
    permanently_delete_on_destroy = true
    solutions                     = ["ChangeTracking"]
    lock                          = { kind = "CanNotDelete" }
  }

  assert {
    condition     = output.resource_id == run.create.resource_id && output.lock_resource_id != null
    error_message = "The workspace should be updated in place and the lock back."
  }
  assert {
    condition     = length(output.role_assignment_resource_ids) + length(output.diagnostic_setting_resource_ids) == 0
    error_message = "The role assignment and the diagnostic setting should be gone."
  }
  assert {
    condition     = keys(output.solution_resource_ids) == ["ChangeTracking"] && output.solution_resource_ids["ChangeTracking"] == run.create.solution_resource_ids["ChangeTracking"]
    error_message = "One solution should be gone, the other kept."
  }
}

run "defaults_in_azure" {
  module {
    source = "./tests/integration/read"
  }

  variables {
    workspace_id = run.reset_under_lock.resource_id
  }

  assert {
    condition     = output.daily_quota_gb == -1 && output.retention_in_days == 30
    error_message = "Azure should report no daily cap and 30 days again."
  }
  assert {
    condition     = output.local_authentication_disabled == true && output.resource_permissions_enabled == true
    error_message = "Azure should report local authentication off and resource permissions on again."
  }
  assert {
    condition     = output.public_network_access == ["Enabled", "Enabled"]
    error_message = "Azure should report public network access enabled again."
  }
}

run "rename_locked_workspace" {
  # A new name replaces the workspace and its solution: the lock goes first, then the old workspace is
  # deleted permanently.
  variables {
    name                          = "law-mlz-mgmt-it-${run.setup.suffix}-b"
    parent_id                     = run.setup.resource_group_id
    location                      = run.setup.location
    permanently_delete_on_destroy = true
    solutions                     = ["ChangeTracking"]
    lock                          = { kind = "CanNotDelete" }
  }

  assert {
    condition     = startswith(output.lock_resource_id, "${output.resource_id}/providers/Microsoft.Authorization/locks/")
    error_message = "The renamed workspace should be locked again."
  }
  assert {
    condition     = endswith(output.solution_resource_ids["ChangeTracking"], "/ChangeTracking(law-mlz-mgmt-it-${run.setup.suffix}-b)")
    error_message = "The solution should follow the renamed workspace."
  }
}

run "first_name_released" {
  # The first workspace was deleted permanently, so its name gives a new workspace, not a recovered one.
  variables {
    name                          = "law-mlz-mgmt-it-${run.setup.suffix}"
    parent_id                     = run.setup.resource_group_id
    location                      = run.setup.location
    permanently_delete_on_destroy = true
  }

  assert {
    condition     = output.workspace_id != run.create.workspace_id
    error_message = "A permanently deleted workspace's name should give a new workspace with a new workspace ID."
  }
}
