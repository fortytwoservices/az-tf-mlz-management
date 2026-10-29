module "data_collection_rule" {
  source   = "./modules/data_collection_rule"
  for_each = local.data_collection_rule_names

  name                       = each.value
  parent_id                  = var.parent_id
  location                   = var.location # the workspace's region, which a rule for the agent must share
  description                = local.data_collection_rules[each.key].description
  data_sources               = local.data_collection_rules[each.key].data_sources
  log_analytics_destinations = { (local.data_collection_rules[each.key].destination) = { workspace_resource_id = module.log_analytics_workspace.resource_id } }
  data_flows                 = local.data_collection_rules[each.key].data_flows
  lock                       = var.lock
  tags                       = var.tags
  resource_types             = var.resource_types.insights_data_collection_rules
  ignore_body_changes        = var.ignore_body_changes.insights_data_collection_rules
  retry                      = var.retry
  timeouts                   = var.timeouts
}
