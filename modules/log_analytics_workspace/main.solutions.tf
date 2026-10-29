# Legacy solutions add tables to the workspace that some data collection rules send to, for example
# change tracking's ConfigurationChange and ConfigurationData (Microsoft Learn, "Migration guidance from
# Change Tracking and inventory using Log Analytics"). Each is named after the workspace and bound to it.
resource "azapi_resource" "solution" {
  for_each = var.solutions

  type      = var.resource_types.operationsmanagement_solutions
  name      = "${each.key}(${azapi_resource.this.name})"
  parent_id = var.parent_id
  location  = var.location
  body = {
    plan = {
      name          = "${each.key}(${azapi_resource.this.name})"
      product       = "OMSGallery/${each.key}"
      publisher     = "Microsoft"
      promotionCode = ""
    }
    properties = {
      workspaceResourceId = azapi_resource.this.id
    }
  }
  ignore_body_changes    = length(var.ignore_body_changes.operationsmanagement_solutions) > 0 ? var.ignore_body_changes.operationsmanagement_solutions : null
  response_export_values = []
  retry                  = var.retry
  tags                   = var.tags

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
