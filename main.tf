module "log_analytics_workspace" {
  source = "./modules/log_analytics_workspace"

  name                                = var.name
  parent_id                           = var.parent_id
  location                            = var.location
  daily_quota_gb                      = var.daily_quota_gb
  local_authentication_enabled        = var.local_authentication_enabled
  permanently_delete_on_destroy       = var.permanently_delete_on_destroy
  public_network_access_for_ingestion = var.public_network_access_for_ingestion
  public_network_access_for_query     = var.public_network_access_for_query
  resource_permissions_enabled        = var.resource_permissions_enabled
  retention_in_days                   = var.retention_in_days
  solutions                           = local.solutions
  lock                                = var.lock
  role_assignments                    = var.role_assignments
  diagnostic_settings                 = var.diagnostic_settings
  tags                                = var.tags
  resource_types                      = var.resource_types.operationalinsights_workspaces
  ignore_body_changes                 = var.ignore_body_changes.operationalinsights_workspaces
  retry                               = var.retry
  timeouts                            = var.timeouts
}
