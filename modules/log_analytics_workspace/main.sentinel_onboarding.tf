module "sentinel_onboarding" {
  source = "../sentinel_onboarding"
  count  = var.sentinel_onboarding == null ? 0 : 1

  parent_id                    = azapi_resource.this.id
  customer_managed_key_enabled = var.sentinel_onboarding.customer_managed_key_enabled
  resource_types               = var.resource_types.securityinsights_onboarding_states
  ignore_body_changes          = var.ignore_body_changes.securityinsights_onboarding_states
  retry                        = var.retry
  timeouts                     = var.timeouts
}
