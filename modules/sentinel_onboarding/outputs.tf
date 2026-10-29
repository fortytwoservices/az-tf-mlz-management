output "lock_dependency" {
  description = "Changes with the onboarding state's body, for the workspace's `lock_dependencies`: the workspace's lock covers this extension resource, so it is removed around any change to it."
  value       = sha256(jsonencode([azapi_resource.this.id, azapi_resource.this.body]))
}

output "name" {
  description = "Name of the onboarding state, always `default`."
  value       = azapi_resource.this.name
}

output "resource_id" {
  description = "Resource ID of the Microsoft Sentinel onboarding state."
  value       = azapi_resource.this.id
}
