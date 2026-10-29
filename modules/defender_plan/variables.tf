variable "name" {
  type        = string
  description = "Name of the Defender plan (the pricing), for example `VirtualMachines`, `SqlServers`, `StorageAccounts`, `KeyVaults`, `Containers`, `CloudPosture`."
  nullable    = false

  validation {
    condition     = can(regex("^[A-Za-z]+$", var.name))
    error_message = "`name` must be a Defender plan name, letters only, for example `VirtualMachines`."
  }
}

variable "parent_id" {
  type        = string
  description = "Resource ID of the subscription the plan applies to, for example `/subscriptions/00000000-0000-0000-0000-000000000000`."
  nullable    = false

  validation {
    condition     = can(provider::azapi::parse_resource_id("Microsoft.Resources/subscriptions", var.parent_id))
    error_message = "`parent_id` must be a subscription resource ID, `/subscriptions/<id>`."
  }
}

variable "extensions" {
  type = map(object({
    enabled               = bool
    additional_properties = optional(map(string))
  }))
  default     = {}
  description = <<DESCRIPTION
Extensions of the plan, keyed by extension name, for example `AgentlessVmScanning` or
`SensitiveDataDiscovery`. Only the extensions listed are managed: the others, and one removed from this
map, stay as Azure has them. Defaults to none.

- `enabled` - Whether the extension is on.
- `additional_properties` - (Optional) The extension's additional properties, for example `{ ExclusionTags = "[]" }`.
DESCRIPTION
  nullable    = false
}

variable "sub_plan" {
  type        = string
  default     = null
  description = "(Optional) Sub-plan of a Standard plan, where the plan has more than one, for example `P1` or `P2` for `VirtualMachines`. Defaults to `null`: not sent, so Azure's sub-plan stands (the full plan for a new one); setting it back to `null` leaves the last one in place."
}

variable "tier" {
  type        = string
  default     = "Standard"
  description = "`Standard` turns the plan on (billed per protected resource); `Free` turns it off. Defaults to `Standard`."
  nullable    = false

  validation {
    condition     = contains(["Free", "Standard"], var.tier)
    error_message = "`tier` must be `Free` or `Standard`."
  }
}
