# Onboards Microsoft Sentinel on the workspace. The API takes one onboarding state per workspace, named
# `default` ("Supports - default"). Not deployed in the sandbox (decided by the user, 2026-10-29): Azure's
# behaviour is unverified until the first customer deployment.
resource "azapi_resource" "this" {
  type      = var.resource_types.securityinsights_onboarding_states
  name      = "default"
  parent_id = var.parent_id
  body = {
    properties = {
      customerManagedKey = var.customer_managed_key_enabled
    }
  }
  ignore_body_changes    = length(var.ignore_body_changes.securityinsights_onboarding_states) > 0 ? var.ignore_body_changes.securityinsights_onboarding_states : null
  response_export_values = []
  retry                  = var.retry

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]
    content {
      create = timeouts.value.create
      read   = timeouts.value.read
      update = timeouts.value.update
      delete = timeouts.value.delete
    }
  }
}
