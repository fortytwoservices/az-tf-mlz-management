# A subscription's Defender plans always exist and can be deleted only at resource scope (Microsoft Learn,
# Pricings REST reference: "Valid only for resource scope"), so the plan is updated in place: `tier =
# "Free"` turns it off, and destroying this leaves Azure as it is. Not deployed in the sandbox (decided by
# the user, 2026-10-29): Azure's behaviour is unverified until the first customer deployment.
resource "azapi_update_resource" "this" {
  type      = var.resource_types.security_pricings
  name      = var.name
  parent_id = var.parent_id
  # Azure fills in a sub-plan, the plan's extensions and their additional properties itself, so whatever is
  # unset is left out rather than sent as null, which would plan a change on every run (Copilot, PR #3):
  # Azure's values stand. Listed extensions are matched by name, and the ones Azure adds are ignored.
  body = {
    properties = merge(
      { pricingTier = var.tier },
      var.sub_plan == null ? null : { subPlan = var.sub_plan },
      length(var.extensions) == 0 ? null : {
        extensions = [for name, extension in var.extensions : merge(
          { name = name, isEnabled = extension.enabled ? "True" : "False" },
          extension.additional_properties == null ? null : { additionalExtensionProperties = extension.additional_properties },
        )]
      },
    )
  }
  ignore_other_items_in_list = ["properties.extensions"]
  list_unique_id_property    = { "properties.extensions" = "name" }
  response_export_values     = []
  retry                      = var.retry

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
