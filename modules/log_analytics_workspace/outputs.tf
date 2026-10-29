output "diagnostic_setting_resource_ids" {
  description = "Resource IDs of the diagnostic settings on the workspace, by key."
  value       = module.interfaces.diagnostic_setting_resource_ids
}

output "lock_resource_id" {
  description = "Resource ID of the workspace's lock; null without one."
  value       = module.interfaces.lock_resource_id
}

output "name" {
  description = "Name of the Log Analytics workspace."
  value       = azapi_resource.this.name
}

output "resource_id" {
  description = "Resource ID of the Log Analytics workspace, known once its solutions exist."
  value       = azapi_resource.this.id
  # Data collection rules that send to a solution's tables use this ID, so they are created after it.
  depends_on = [azapi_resource.solution]
}

output "sentinel_onboarding_resource_id" {
  description = "Resource ID of the Microsoft Sentinel onboarding state; null when Sentinel is not onboarded."
  value       = length(module.sentinel_onboarding) == 0 ? null : module.sentinel_onboarding[0].resource_id
}

output "solution_resource_ids" {
  description = "Resource IDs of the solutions on the workspace, by product name."
  value       = { for product, solution in azapi_resource.solution : product => solution.id }
}

output "role_assignment_resource_ids" {
  description = "Resource IDs of the role assignments on the workspace, by key."
  value       = module.interfaces.role_assignment_resource_ids
}

output "workspace_id" {
  description = "Workspace (customer) ID of the Log Analytics workspace, a GUID."
  value       = azapi_resource.this.output.properties.customerId
}
