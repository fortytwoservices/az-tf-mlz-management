output "name" {
  description = "Name of the Defender plan."
  value       = azapi_update_resource.this.name
}

output "resource_id" {
  description = "Resource ID of the Defender plan's pricing."
  value       = azapi_update_resource.this.id
}
