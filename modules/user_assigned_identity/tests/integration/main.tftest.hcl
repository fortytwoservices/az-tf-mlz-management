# Real Azure, no mocks: ARM_SUBSCRIPTION_ID=<test subscription> terraform test -test-directory=tests/integration
# Proves what mocks cannot: the isolation scope is set and reset in Azure, the identity is updated under
# its lock, and a locked identity is replaced in one apply.

run "setup" {
  module {
    source = "./tests/integration/setup"
  }
}

run "create" {
  variables {
    name      = "id-mlz-mgmt-it-${run.setup.suffix}"
    parent_id = run.setup.resource_group_id
    location  = run.setup.location
    lock      = { kind = "CanNotDelete" }
    role_assignments = {
      reader = { role_definition_id_or_name = "Reader", principal_id = run.setup.object_id }
    }
  }

  assert {
    condition     = can(regex("^[0-9a-f-]{36}$", output.principal_id)) && can(regex("^[0-9a-f-]{36}$", output.client_id))
    error_message = "principal_id and client_id should be read back from Azure."
  }
  assert {
    condition     = output.lock_resource_id != null && length(output.role_assignment_resource_ids) == 1
    error_message = "The lock and the role assignment should be created."
  }
}

run "update_under_lock" {
  variables {
    name            = "id-mlz-mgmt-it-${run.setup.suffix}"
    parent_id       = run.setup.resource_group_id
    location        = run.setup.location
    lock            = { kind = "CanNotDelete" }
    isolation_scope = "Regional"
    tags            = { updated = "true" }
    role_assignments = {
      reader = { role_definition_id_or_name = "Reader", principal_id = run.setup.object_id }
    }
  }

  assert {
    condition     = output.resource_id == run.create.resource_id && azapi_resource.this.tags == tomap({ updated = "true" })
    error_message = "The identity should be updated in place."
  }
}

run "isolation_scope_set_in_azure" {
  module {
    source = "./tests/integration/read_identity"
  }

  variables {
    identity_id = run.update_under_lock.resource_id
  }

  assert {
    condition     = output.isolation_scope == "Regional"
    error_message = "Azure should report the Regional isolation scope set by update_under_lock."
  }
}

run "reset" {
  variables {
    name      = "id-mlz-mgmt-it-${run.setup.suffix}"
    parent_id = run.setup.resource_group_id
    location  = run.setup.location
    lock      = { kind = "CanNotDelete" }
  }

  assert {
    condition     = length(output.role_assignment_resource_ids) == 0 && output.lock_resource_id != null
    error_message = "The role assignment should be gone and the lock back."
  }
}

run "isolation_scope_reset_in_azure" {
  module {
    source = "./tests/integration/read_identity"
  }

  variables {
    identity_id = run.reset.resource_id
  }

  assert {
    condition     = output.isolation_scope == "None"
    error_message = "Azure should report the default isolation scope again once isolation_scope is no longer set."
  }
}

run "replace_locked_identity" {
  # A new name replaces the identity. The lock goes first and the pause is replaced with the identity,
  # so the old identity is deleted only after the lock deletion has propagated.
  variables {
    name      = "id-mlz-mgmt-it-${run.setup.suffix}-renamed"
    parent_id = run.setup.resource_group_id
    location  = run.setup.location
    lock      = { kind = "CanNotDelete" }
  }

  assert {
    condition     = output.name == "id-mlz-mgmt-it-${run.setup.suffix}-renamed" && startswith(output.lock_resource_id, "${output.resource_id}/providers/Microsoft.Authorization/locks/")
    error_message = "The identity should be replaced and locked again."
  }
}
