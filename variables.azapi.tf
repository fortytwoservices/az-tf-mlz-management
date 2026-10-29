variable "ignore_body_changes" {
  type = object({
    operationalinsights_workspaces = optional(object({
      operationalinsights_workspaces = optional(list(string), [])
      authorization_locks            = optional(list(string), [])
      authorization_role_assignments = optional(list(string), [])
      insights_diagnostic_settings   = optional(list(string), [])
      operationsmanagement_solutions = optional(list(string), [])
      securityinsights_onboarding_states = optional(object({
        securityinsights_onboarding_states = optional(list(string), [])
      }), {})
    }), {})
    insights_data_collection_rules = optional(object({
      insights_data_collection_rules = optional(list(string), [])
      authorization_locks            = optional(list(string), [])
      authorization_role_assignments = optional(list(string), [])
      insights_diagnostic_settings   = optional(list(string), [])
    }), {})
    managedidentity_user_assigned_identities = optional(object({
      managedidentity_user_assigned_identities = optional(list(string), [])
      authorization_locks                      = optional(list(string), [])
      authorization_role_assignments           = optional(list(string), [])
    }), {})
  })
  default     = {}
  description = <<DESCRIPTION
Paths in each resource's `body` whose changes the AzAPI provider ignores. Prefer Terraform's `lifecycle.ignore_changes` when the paths are static; use this variable when the paths must be derived from variables or other non-static values.

Paths use dot notation, for example `properties.retentionInDays`. Individual list items cannot be targeted; ignore the whole list property instead. Configuration changes at an ignored path are **not** sent to Azure until that path is removed from the list. Changes take effect only after an apply, because the value is held in provider-private state.

- `operationalinsights_workspaces` - Slot for `modules/log_analytics_workspace`: its `operationalinsights_workspaces`, `authorization_locks`, `authorization_role_assignments`, `insights_diagnostic_settings`, `operationsmanagement_solutions`, and its slot for `modules/sentinel_onboarding` (`securityinsights_onboarding_states`). Defender plans have none: they are updated in place (`azapi_update_resource`), which has no `ignore_body_changes`.
- `insights_data_collection_rules` - Slot for `modules/data_collection_rule`, applied to every rule: its `insights_data_collection_rules`, `authorization_locks`, `authorization_role_assignments` and `insights_diagnostic_settings`.
- `managedidentity_user_assigned_identities` - Slot for `modules/user_assigned_identity`: its `managedidentity_user_assigned_identities`, `authorization_locks` and `authorization_role_assignments`.
DESCRIPTION
  nullable    = false
}

variable "resource_types" {
  type = object({
    operationalinsights_workspaces = optional(object({
      operationalinsights_workspaces = optional(string)
      authorization_locks            = optional(string)
      authorization_role_assignments = optional(string)
      insights_diagnostic_settings   = optional(string)
      operationsmanagement_solutions = optional(string)
      securityinsights_onboarding_states = optional(object({
        securityinsights_onboarding_states = optional(string)
      }), {})
    }), {})
    insights_data_collection_rules = optional(object({
      insights_data_collection_rules = optional(string)
      authorization_locks            = optional(string)
      authorization_role_assignments = optional(string)
      insights_diagnostic_settings   = optional(string)
    }), {})
    managedidentity_user_assigned_identities = optional(object({
      managedidentity_user_assigned_identities = optional(string)
      authorization_locks                      = optional(string)
      authorization_role_assignments           = optional(string)
    }), {})
    security_pricings = optional(object({
      security_pricings = optional(string)
    }), {})
  })
  default     = {}
  description = <<DESCRIPTION
Override the AzAPI `<provider>/<resource>@<api-version>` strings used by the submodules. Each key defaults to a tested value in its submodule; supply only the keys you want to override.

- `operationalinsights_workspaces` - Slot for `modules/log_analytics_workspace` (default `Microsoft.OperationalInsights/workspaces@2025-07-01`), with its lock, role assignment, diagnostic setting and solution types, and its slot for `modules/sentinel_onboarding` (`securityinsights_onboarding_states`, default `Microsoft.SecurityInsights/onboardingStates@2025-09-01`).
- `insights_data_collection_rules` - Slot for `modules/data_collection_rule` (default `Microsoft.Insights/dataCollectionRules@2024-03-11`), with its lock, role assignment and diagnostic setting types.
- `managedidentity_user_assigned_identities` - Slot for `modules/user_assigned_identity` (default `Microsoft.ManagedIdentity/userAssignedIdentities@2024-11-30`), with its lock and role assignment types.
- `security_pricings` - Slot for `modules/defender_plan` (default `Microsoft.Security/pricings@2024-01-01`).
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
Retry configuration applied to every `azapi` resource managed by the module and its submodules. Defaults retry `InvalidOutputTable`, which Azure returns for a data collection rule whose destination table does not exist yet: a solution adds its tables about a minute after it is created (sandbox, 2026-10-28). Any field can be overridden.

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
Default per-operation timeouts applied to every `azapi` resource managed by the module and its submodules. Defaults to `null` (provider defaults). Each value is a Go duration string (e.g. `30m`, `1h`).

- `create` - (Optional) Timeout for create operations.
- `read`   - (Optional) Timeout for read operations.
- `update` - (Optional) Timeout for update operations.
- `delete` - (Optional) Timeout for delete operations.
DESCRIPTION
}
