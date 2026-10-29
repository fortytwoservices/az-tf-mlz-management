resource "azapi_resource" "this" {
  type      = var.resource_types.operationalinsights_workspaces
  name      = var.name
  parent_id = var.parent_id
  location  = var.location
  # Every property is sent, so that changing a setting back reaches Azure: azapi compares only the keys in
  # the body. No daily cap is Azure's -1.
  body = {
    properties = {
      features = {
        disableLocalAuth                            = !var.local_authentication_enabled
        enableLogAccessUsingOnlyResourcePermissions = var.resource_permissions_enabled
      }
      publicNetworkAccessForIngestion = var.public_network_access_for_ingestion
      publicNetworkAccessForQuery     = var.public_network_access_for_query
      retentionInDays                 = var.retention_in_days
      sku                             = { name = "PerGB2018" }
      workspaceCapping                = { dailyQuotaGb = var.daily_quota_gb == null ? -1 : var.daily_quota_gb }
    }
  }
  # A deleted workspace stays recoverable for 14 days with its name reserved; force=true deletes it
  # permanently and releases the name (Microsoft Learn, "Delete and recover a Log Analytics workspace").
  delete_query_parameters = var.permanently_delete_on_destroy ? { force = ["true"] } : null
  ignore_body_changes     = length(var.ignore_body_changes.operationalinsights_workspaces) > 0 ? var.ignore_body_changes.operationalinsights_workspaces : null
  response_export_values  = ["properties.customerId"]
  retry                   = var.retry
  tags                    = var.tags

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
