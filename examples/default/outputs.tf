# avm-ptn-alz's policy_default_values, ready to pass: each value is a JSON object with a single `value`
# attribute (its input contract, "to mitigate issues with the Terraform type system").
output "policy_default_values" {
  description = "The management resources as `avm-ptn-alz`'s `policy_default_values`: by default name, each value `jsonencode({ value = ... })`."
  value = { for name, value in {
    log_analytics_workspace_id                  = module.management.resource_id
    ama_change_tracking_data_collection_rule_id = module.management.data_collection_rule_resource_ids.change_tracking
    ama_vm_insights_data_collection_rule_id     = module.management.data_collection_rule_resource_ids.vm_insights
    ama_mdfc_sql_data_collection_rule_id        = module.management.data_collection_rule_resource_ids.defender_sql
    ama_user_assigned_managed_identity_id       = module.management.user_assigned_identity.resource_id
    ama_user_assigned_managed_identity_name     = module.management.user_assigned_identity.name
  } : name => jsonencode({ value = value }) }
}

output "workspace_id" {
  description = "Workspace (customer) ID of the Log Analytics workspace."
  value       = module.management.workspace_id
}
