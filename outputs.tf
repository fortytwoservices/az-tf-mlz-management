output "data_collection_rule_resource_ids" {
  description = "Resource IDs of the data collection rules the module created, by kind: `change_tracking`, `vm_insights`, `defender_sql`. For `avm-ptn-alz`'s `policy_default_values`: `ama_change_tracking_data_collection_rule_id`, `ama_vm_insights_data_collection_rule_id` and `ama_mdfc_sql_data_collection_rule_id`."
  value       = { for kind, rule in module.data_collection_rule : kind => rule.resource_id }
}

output "defender_plan_resource_ids" {
  description = "Resource IDs of the Defender plans the module sets, by key of `defender_plans`."
  value       = { for key, plan in module.defender_plan : key => plan.resource_id }
}

output "name" {
  description = "Name of the Log Analytics workspace."
  value       = module.log_analytics_workspace.name
}

output "resource_id" {
  description = "Resource ID of the Log Analytics workspace (`log_analytics_workspace_id` in `avm-ptn-alz`'s `policy_default_values`)."
  value       = module.log_analytics_workspace.resource_id
}

output "sentinel_onboarding_resource_id" {
  description = "Resource ID of the workspace's Microsoft Sentinel onboarding state; null when Sentinel is not onboarded."
  value       = module.log_analytics_workspace.sentinel_onboarding_resource_id
}

output "user_assigned_identity" {
  description = "The Azure Monitor Agent's user-assigned identity: `resource_id`, `name`, `principal_id` and `client_id`; null when none was created. For `avm-ptn-alz`'s `policy_default_values`: `ama_user_assigned_managed_identity_id` and `ama_user_assigned_managed_identity_name`."
  value = length(module.user_assigned_identity) == 0 ? null : {
    resource_id  = module.user_assigned_identity[0].resource_id
    name         = module.user_assigned_identity[0].name
    principal_id = module.user_assigned_identity[0].principal_id
    client_id    = module.user_assigned_identity[0].client_id
  }
}

output "workspace_id" {
  description = "Workspace (customer) ID of the Log Analytics workspace, a GUID."
  value       = module.log_analytics_workspace.workspace_id
}
