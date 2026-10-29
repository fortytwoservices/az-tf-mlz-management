output "diagnostic_setting_resource_ids" {
  description = "Resource IDs of the diagnostic settings on the data collection rule, by key."
  value       = module.interfaces.diagnostic_setting_resource_ids
}

output "lock_resource_id" {
  description = "Resource ID of the data collection rule's lock; null without one."
  value       = module.interfaces.lock_resource_id
}

output "name" {
  description = "Name of the data collection rule."
  value       = azapi_resource.this.name
}

output "resource_id" {
  description = "Resource ID of the data collection rule."
  value       = azapi_resource.this.id
}

output "role_assignment_resource_ids" {
  description = "Resource IDs of the role assignments on the data collection rule, by key."
  value       = module.interfaces.role_assignment_resource_ids
}
