variable "parent_id" {
  type        = string
  description = "Resource ID of the Log Analytics workspace to onboard Microsoft Sentinel on."
  nullable    = false

  validation {
    condition     = can(provider::azapi::parse_resource_id("Microsoft.OperationalInsights/workspaces", var.parent_id))
    error_message = "`parent_id` must be a Log Analytics workspace resource ID."
  }
}

variable "customer_managed_key_enabled" {
  type        = bool
  default     = false
  description = "Whether Microsoft Sentinel uses the customer-managed key of the workspace's dedicated cluster. Defaults to `false`. Set it at onboarding: whether Azure changes it afterwards is unverified."
  nullable    = false
}
