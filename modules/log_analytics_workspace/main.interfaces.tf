module "interfaces" {
  source = "git::https://github.com/fortytwoservices/az-tf-mlz-interfaces.git?ref=v0.1.1"

  resource_id = azapi_resource.this.id
  location    = var.location
  # Role definitions are looked up by name in the resource group, which exists before the workspace, so
  # an unknown role name fails during plan.
  role_assignment_definition_scope = var.parent_id
  lock                             = var.lock
  role_assignments                 = var.role_assignments
  diagnostic_settings              = var.diagnostic_settings
  # A solution writes to the workspace, and the lock covers the Sentinel onboarding state (an extension
  # resource under it), so the lock is removed around changes to either.
  lock_dependencies = merge(
    { for product, solution in azapi_resource.solution : "solution/${product}" => sha256(jsonencode([solution.id, solution.body, solution.tags])) },
    { for index, onboarding in module.sentinel_onboarding : "sentinel/${index}" => onboarding.lock_dependency },
  )
  resource_types      = var.resource_types # its interface keys are read
  ignore_body_changes = var.ignore_body_changes
  retry               = var.retry
  timeouts            = var.timeouts
}
