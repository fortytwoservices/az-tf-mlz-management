mock_provider "azapi" {
  mock_resource "azapi_resource" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.OperationalInsights/workspaces/law-test/providers/Microsoft.SecurityInsights/onboardingStates/default"
    }
  }
}

variables {
  parent_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.OperationalInsights/workspaces/law-test"
}

run "defaults" {
  command = apply

  assert {
    condition     = azapi_resource.this.type == "Microsoft.SecurityInsights/onboardingStates@2025-09-01"
    error_message = "The onboarding state should use the default resource type."
  }
  assert {
    condition     = azapi_resource.this.name == "default" && azapi_resource.this.parent_id == var.parent_id
    error_message = "The onboarding state should be named default, on the workspace."
  }
  assert {
    condition     = jsonencode(azapi_resource.this.body) == jsonencode({ properties = { customerManagedKey = false } })
    error_message = "The customer-managed key flag should be sent, false by default."
  }
  assert {
    condition     = azapi_resource.this.retry == null && azapi_resource.this.timeouts == null
    error_message = "retry and timeouts should be unset by default."
  }
  assert {
    condition     = output.resource_id == azapi_resource.this.id && output.name == "default"
    error_message = "resource_id and name should come from the onboarding state."
  }
  assert {
    condition     = output.lock_dependency == sha256(jsonencode([azapi_resource.this.id, azapi_resource.this.body]))
    error_message = "lock_dependency should hash the ID and the body."
  }
}

run "customer_managed_key" {
  command = apply

  variables {
    customer_managed_key_enabled = true
  }

  assert {
    condition     = azapi_resource.this.body.properties.customerManagedKey == true
    error_message = "customer_managed_key_enabled should map to properties.customerManagedKey."
  }
  assert {
    condition     = output.lock_dependency != run.defaults.lock_dependency
    error_message = "lock_dependency should change with the body."
  }
}

run "azapi_settings" {
  command = apply

  variables {
    resource_types      = { securityinsights_onboarding_states = "Microsoft.SecurityInsights/onboardingStates@2024-09-01" }
    ignore_body_changes = { securityinsights_onboarding_states = ["properties.customerManagedKey"] }
    retry               = { error_message_regex = ["AnotherOperationInProgress"] }
    timeouts            = { create = "15m" }
  }

  assert {
    condition     = azapi_resource.this.type == "Microsoft.SecurityInsights/onboardingStates@2024-09-01"
    error_message = "The resource_types override should reach the onboarding state."
  }
  assert {
    condition     = azapi_resource.this.retry.error_message_regex == tolist(["AnotherOperationInProgress"]) && azapi_resource.this.timeouts.create == "15m"
    error_message = "retry and timeouts should reach the onboarding state."
  }
}

run "invalid_parent_id" {
  command = plan

  variables {
    parent_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test"
  }

  expect_failures = [var.parent_id]
}
