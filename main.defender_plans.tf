module "defender_plan" {
  source   = "./modules/defender_plan"
  for_each = var.defender_plans

  name           = each.value.plan
  parent_id      = each.value.subscription_id
  tier           = each.value.tier
  sub_plan       = each.value.sub_plan
  extensions     = each.value.extensions
  resource_types = var.resource_types.security_pricings
  retry          = var.retry
  timeouts       = var.timeouts
}
