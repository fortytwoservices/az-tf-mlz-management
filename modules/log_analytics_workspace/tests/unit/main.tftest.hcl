mock_provider "azapi" {
  mock_resource "azapi_resource" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.OperationalInsights/workspaces/law-test"
      output = {
        properties = {
          customerId = "77777777-7777-7777-7777-777777777777"
        }
      }
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
    condition     = azapi_resource.this.type == "Microsoft.OperationalInsights/workspaces@2025-07-01"
    error_message = "The workspace should use the default resource type."
  }
  assert {
    condition     = azapi_resource.this.name == var.name && azapi_resource.this.parent_id == var.parent_id && azapi_resource.this.location == var.location
    error_message = "The workspace should be created with name, parent_id and location."
  }
  assert {
    condition = jsonencode(azapi_resource.this.body) == jsonencode({
      properties = {
        features = {
          disableLocalAuth                            = true
          enableLogAccessUsingOnlyResourcePermissions = true
        }
        publicNetworkAccessForIngestion = "Enabled"
        publicNetworkAccessForQuery     = "Enabled"
        retentionInDays                 = 30
        sku                             = { name = "PerGB2018" }
        workspaceCapping                = { dailyQuotaGb = -1 }
      }
    })
    error_message = "Every property should be sent with its default: local authentication off, resource permissions on, public access on, 30 days, PerGB2018, no daily cap (-1)."
  }
  assert {
    condition     = azapi_resource.this.delete_query_parameters == null
    error_message = "A destroyed workspace should go into soft delete by default."
  }
  assert {
    condition     = azapi_resource.this.retry == null && azapi_resource.this.timeouts == null
    error_message = "retry and timeouts should be unset by default."
  }
  assert {
    condition     = output.lock_resource_id == null && length(output.role_assignment_resource_ids) + length(output.diagnostic_setting_resource_ids) + length(azapi_resource.solution) == 0
    error_message = "No lock, role assignment, diagnostic setting or solution should be created by default."
  }
  assert {
    condition     = output.resource_id == azapi_resource.this.id && output.name == var.name
    error_message = "resource_id and name should come from the workspace."
  }
  assert {
    condition     = output.workspace_id == "77777777-7777-7777-7777-777777777777"
    error_message = "workspace_id should come from the exported customer ID."
  }
}

run "workspace_options" {
  command = apply

  variables {
    daily_quota_gb                      = 2.5
    local_authentication_enabled        = true
    permanently_delete_on_destroy       = true
    public_network_access_for_ingestion = "Disabled"
    public_network_access_for_query     = "Disabled"
    resource_permissions_enabled        = false
    retention_in_days                   = 90
    tags                                = { environment = "test" }
  }

  assert {
    condition = jsonencode(azapi_resource.this.body.properties) == jsonencode({
      features = {
        disableLocalAuth                            = false
        enableLogAccessUsingOnlyResourcePermissions = false
      }
      publicNetworkAccessForIngestion = "Disabled"
      publicNetworkAccessForQuery     = "Disabled"
      retentionInDays                 = 90
      sku                             = { name = "PerGB2018" }
      workspaceCapping                = { dailyQuotaGb = 2.5 }
    })
    error_message = "Each input should map to its workspace property."
  }
  assert {
    condition     = jsonencode(azapi_resource.this.delete_query_parameters) == jsonencode({ force = ["true"] })
    error_message = "permanently_delete_on_destroy should send force=true on delete."
  }
  assert {
    condition     = azapi_resource.this.tags == tomap({ environment = "test" })
    error_message = "tags should be set on the workspace."
  }
}

run "solutions" {
  command = apply

  variables {
    solutions = ["ChangeTracking", "SQLVulnerabilityAssessment"]
    tags      = { environment = "test" }
  }

  assert {
    condition     = keys(azapi_resource.solution) == ["ChangeTracking", "SQLVulnerabilityAssessment"]
    error_message = "One solution should be created per product."
  }
  assert {
    condition     = azapi_resource.solution["ChangeTracking"].name == "ChangeTracking(law-test)" && azapi_resource.solution["ChangeTracking"].parent_id == var.parent_id && azapi_resource.solution["ChangeTracking"].location == var.location
    error_message = "A solution should be named after its product and the workspace, in the workspace's resource group and region."
  }
  assert {
    condition = jsonencode(azapi_resource.solution["ChangeTracking"].body) == jsonencode({
      plan = {
        name          = "ChangeTracking(law-test)"
        product       = "OMSGallery/ChangeTracking"
        publisher     = "Microsoft"
        promotionCode = ""
      }
      properties = { workspaceResourceId = azapi_resource.this.id }
    })
    error_message = "A solution should be the Microsoft gallery product, bound to the workspace."
  }
  assert {
    condition     = azapi_resource.solution["ChangeTracking"].type == "Microsoft.OperationsManagement/solutions@2015-11-01-preview" && azapi_resource.solution["ChangeTracking"].tags == tomap({ environment = "test" })
    error_message = "Solutions should use the default resource type and take the tags."
  }
  assert {
    condition     = keys(output.solution_resource_ids) == ["ChangeTracking", "SQLVulnerabilityAssessment"]
    error_message = "Solution IDs should be output by product."
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
      self = {
        workspace_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.OperationalInsights/workspaces/law-central"
        logs                  = [{ category_group = "allLogs" }]
        metrics               = [{ category = "AllMetrics" }]
      }
    }
  }

  # Their behaviour is tested in az-tf-mlz-interfaces; a test sees only its outputs.
  assert {
    condition     = output.lock_resource_id != null && keys(output.role_assignment_resource_ids) == ["reader"] && keys(output.diagnostic_setting_resource_ids) == ["self"]
    error_message = "The lock, role assignments and diagnostic settings should be created through az-tf-mlz-interfaces."
  }
}

run "azapi_settings_reach_every_resource" {
  command = apply

  # ignore_body_changes is write-only, so a test cannot read it back; which resource reads which slot is
  # left to review. The interface keys go to az-tf-mlz-interfaces, whose tests check them.
  variables {
    lock = { kind = "CanNotDelete" }
    resource_types = {
      operationalinsights_workspaces = "Microsoft.OperationalInsights/workspaces@2025-02-01"
      authorization_locks            = "Microsoft.Authorization/locks@2016-09-01"
      authorization_role_assignments = "Microsoft.Authorization/roleAssignments@2020-04-01-preview"
      insights_diagnostic_settings   = "Microsoft.Insights/diagnosticSettings@2021-05-01-preview"
      operationsmanagement_solutions = "Microsoft.OperationsManagement/solutions@2015-11-01-preview"
    }
    solutions = ["ChangeTracking"]
    ignore_body_changes = {
      operationalinsights_workspaces = ["properties.retentionInDays"]
      authorization_locks            = ["properties.notes"]
      authorization_role_assignments = ["properties.description"]
      insights_diagnostic_settings   = ["properties.logs"]
      operationsmanagement_solutions = ["plan.promotionCode"]
    }
    retry = {
      error_message_regex = ["AnotherOperationInProgress"]
    }
    timeouts = {
      create = "15m"
    }
  }

  assert {
    condition     = azapi_resource.this.type == "Microsoft.OperationalInsights/workspaces@2025-02-01"
    error_message = "The resource_types override should reach the workspace."
  }
  assert {
    condition     = azapi_resource.this.retry.error_message_regex == tolist(["AnotherOperationInProgress"]) && azapi_resource.this.timeouts.create == "15m"
    error_message = "retry and timeouts should reach the workspace."
  }
  assert {
    condition     = azapi_resource.solution["ChangeTracking"].retry.error_message_regex == tolist(["AnotherOperationInProgress"]) && azapi_resource.solution["ChangeTracking"].timeouts.create == "15m"
    error_message = "retry and timeouts should reach the solutions."
  }
}

run "invalid_name_too_short" {
  command = plan

  variables {
    name = "law"
  }

  expect_failures = [var.name]
}

run "invalid_name_ends_with_hyphen" {
  command = plan

  variables {
    name = "law-test-"
  }

  expect_failures = [var.name]
}

run "invalid_name_underscore" {
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

run "invalid_retention_too_short" {
  command = plan

  variables {
    retention_in_days = 29
  }

  expect_failures = [var.retention_in_days]
}

run "invalid_retention_too_long" {
  command = plan

  variables {
    retention_in_days = 731
  }

  expect_failures = [var.retention_in_days]
}

run "invalid_retention_fraction" {
  command = plan

  variables {
    retention_in_days = 30.5
  }

  expect_failures = [var.retention_in_days]
}

run "invalid_daily_quota" {
  command = plan

  variables {
    daily_quota_gb = 0
  }

  expect_failures = [var.daily_quota_gb]
}

run "invalid_public_network_access_for_ingestion" {
  command = plan

  variables {
    public_network_access_for_ingestion = "SecuredByPerimeter"
  }

  expect_failures = [var.public_network_access_for_ingestion]
}

run "invalid_public_network_access_for_query" {
  command = plan

  variables {
    public_network_access_for_query = "enabled"
  }

  expect_failures = [var.public_network_access_for_query]
}

run "invalid_solution" {
  command = plan

  variables {
    solutions = ["OMSGallery/ChangeTracking"]
  }

  expect_failures = [var.solutions]
}

run "invalid_lock_kind" {
  command = plan

  variables {
    lock = { kind = "Delete" }
  }

  expect_failures = [var.lock]
}
