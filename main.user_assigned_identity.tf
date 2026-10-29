module "user_assigned_identity" {
  source = "./modules/user_assigned_identity"
  count  = var.user_assigned_identity == null ? 0 : 1

  name                = var.user_assigned_identity.name
  parent_id           = var.parent_id
  location            = var.location
  lock                = var.lock
  tags                = var.tags
  resource_types      = var.resource_types.managedidentity_user_assigned_identities
  ignore_body_changes = var.ignore_body_changes.managedidentity_user_assigned_identities
  retry               = var.retry
  timeouts            = var.timeouts
}
