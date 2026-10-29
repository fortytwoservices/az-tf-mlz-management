variable "ignore_body_changes" {
  type = object({
    insights_data_collection_rules = optional(list(string), [])
    authorization_locks            = optional(list(string), [])
    authorization_role_assignments = optional(list(string), [])
    insights_diagnostic_settings   = optional(list(string), [])
  })
  default     = {}
  description = <<DESCRIPTION
Paths in each resource's `body` whose changes the AzAPI provider ignores. Prefer Terraform's `lifecycle.ignore_changes` when the paths are static; use this variable when the paths must be derived from variables or other non-static values.

Paths use dot notation, for example `properties.description`. Individual list items cannot be targeted; ignore the whole list property instead. Configuration changes at an ignored path are **not** sent to Azure until that path is removed from the list. Changes take effect only after an apply, because the value is held in provider-private state.

- `insights_data_collection_rules` - Ignored body paths for the data collection rule.
- `authorization_locks` - Ignored body paths for the lock.
- `authorization_role_assignments` - Ignored body paths for the role assignments.
- `insights_diagnostic_settings` - Ignored body paths for the diagnostic settings.
DESCRIPTION
  nullable    = false
}

variable "resource_types" {
  type = object({
    insights_data_collection_rules = optional(string, "Microsoft.Insights/dataCollectionRules@2024-03-11")
    authorization_locks            = optional(string, "Microsoft.Authorization/locks@2020-05-01")
    authorization_role_assignments = optional(string, "Microsoft.Authorization/roleAssignments@2022-04-01")
    insights_diagnostic_settings   = optional(string, "Microsoft.Insights/diagnosticSettings@2021-05-01-preview")
  })
  default     = {}
  description = <<DESCRIPTION
Override the AzAPI `<provider>/<resource>@<api-version>` strings used by this module. Each key defaults to a tested value; supply only the keys you want to override.

- `insights_data_collection_rules` - The data collection rule.
- `authorization_locks` - The lock on the data collection rule.
- `authorization_role_assignments` - Role assignments on the data collection rule.
- `insights_diagnostic_settings` - Diagnostic settings on the data collection rule.
DESCRIPTION
  nullable    = false
}

variable "retry" {
  type = object({
    error_message_regex  = optional(list(string), ["InvalidOutputTable"])
    interval_seconds     = optional(number, 30)
    max_interval_seconds = optional(number, 300)
  })
  default     = {}
  description = <<DESCRIPTION
Retry configuration applied to every `azapi` resource managed by the module. Defaults retry `InvalidOutputTable`, which Azure returns for a rule whose destination table does not exist yet: a solution adds its tables about a minute after it is created (sandbox, 2026-10-28). Any field can be overridden.

- `error_message_regex`  - (Optional) A list of regex patterns matching error messages that trigger a retry. Defaults to `["InvalidOutputTable"]`.
- `interval_seconds`     - (Optional) Initial interval between retries in seconds. Defaults to `30`.
- `max_interval_seconds` - (Optional) Maximum interval between retries in seconds. Defaults to `300`.

See <https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource#retry> for full semantics.
DESCRIPTION
}

variable "timeouts" {
  type = object({
    create = optional(string)
    read   = optional(string)
    update = optional(string)
    delete = optional(string)
  })
  default     = null
  description = <<DESCRIPTION
Default per-operation timeouts applied to every `azapi` resource managed by the module. Defaults to `null` (provider defaults). Each value is a Go duration string (e.g. `30m`, `1h`).

- `create` - (Optional) Timeout for create operations.
- `read`   - (Optional) Timeout for read operations.
- `update` - (Optional) Timeout for update operations.
- `delete` - (Optional) Timeout for delete operations.
DESCRIPTION
}
