# A subscription's Defender plans always exist and can be deleted only at resource scope (Microsoft Learn,
# Pricings REST reference: "Valid only for resource scope"), so the plan is updated in place: `tier =
# "Free"` turns it off, and destroying this leaves Azure as it is. Every property is sent, null when
# unset. Not deployed in the sandbox (decided by the user, 2026-10-29): Azure's behaviour is unverified
# until the first customer deployment.
resource "azapi_update_resource" "this" {
  type      = var.resource_types.security_pricings
  name      = var.name
  parent_id = var.parent_id
  body = {
    properties = {
      pricingTier = var.tier
      subPlan     = var.sub_plan
      extensions = length(var.extensions) == 0 ? null : [for name, extension in var.extensions : {
        name                          = name
        isEnabled                     = extension.enabled ? "True" : "False"
        additionalExtensionProperties = extension.additional_properties
      }]
    }
  }
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
