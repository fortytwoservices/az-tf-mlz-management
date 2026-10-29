mock_provider "azapi" {
  mock_resource "azapi_update_resource" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/providers/Microsoft.Security/pricings/VirtualMachines"
    }
  }
}

variables {
  name      = "VirtualMachines"
  parent_id = "/subscriptions/00000000-0000-0000-0000-000000000000"
}

run "defaults" {
  command = apply

  assert {
    condition     = azapi_update_resource.this.type == "Microsoft.Security/pricings@2024-01-01"
    error_message = "The plan should use the default resource type."
  }
  assert {
    condition     = azapi_update_resource.this.name == var.name && azapi_update_resource.this.parent_id == var.parent_id
    error_message = "The plan should be the named pricing on the subscription."
  }
  assert {
    condition     = jsonencode(azapi_update_resource.this.body) == jsonencode({ properties = { pricingTier = "Standard", subPlan = null, extensions = null } })
    error_message = "Every property should be sent: Standard, no sub-plan and no extensions as null."
  }
  assert {
    condition     = azapi_update_resource.this.retry == null && azapi_update_resource.this.timeouts == null
    error_message = "retry and timeouts should be unset by default."
  }
  assert {
    condition     = output.resource_id == azapi_update_resource.this.id && output.name == var.name
    error_message = "resource_id and name should come from the plan."
  }
}

run "sub_plan_and_extensions" {
  command = apply

  variables {
    sub_plan = "P2"
    extensions = {
      MdeDesignatedSubscription = { enabled = false }
      AgentlessVmScanning       = { enabled = true, additional_properties = { ExclusionTags = "[]" } }
    }
  }

  assert {
    condition = jsonencode(azapi_update_resource.this.body.properties) == jsonencode({
      pricingTier = "Standard"
      subPlan     = "P2"
      extensions = [
        { name = "AgentlessVmScanning", isEnabled = "True", additionalExtensionProperties = { ExclusionTags = "[]" } },
        { name = "MdeDesignatedSubscription", isEnabled = "False", additionalExtensionProperties = null },
      ]
    })
    error_message = "The sub-plan and the extensions, in key order with isEnabled as a string, should be sent."
  }
}

run "free" {
  command = apply

  variables {
    tier = "Free"
  }

  assert {
    condition     = azapi_update_resource.this.body.properties.pricingTier == "Free"
    error_message = "tier Free should turn the plan off."
  }
}

run "azapi_settings" {
  command = apply

  variables {
    resource_types = { security_pricings = "Microsoft.Security/pricings@2023-01-01" }
    retry          = { error_message_regex = ["Conflict"] }
    timeouts       = { update = "15m" }
  }

  assert {
    condition     = azapi_update_resource.this.type == "Microsoft.Security/pricings@2023-01-01"
    error_message = "The resource_types override should reach the plan."
  }
  assert {
    condition     = azapi_update_resource.this.retry.error_message_regex == tolist(["Conflict"]) && azapi_update_resource.this.timeouts.update == "15m"
    error_message = "retry and timeouts should reach the plan."
  }
}

run "invalid_name" {
  command = plan

  variables {
    name = "Virtual Machines"
  }

  expect_failures = [var.name]
}

run "invalid_parent_id" {
  command = plan

  variables {
    parent_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test"
  }

  expect_failures = [var.parent_id]
}

run "invalid_tier" {
  command = plan

  variables {
    tier = "Premium"
  }

  expect_failures = [var.tier]
}
