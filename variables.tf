variable "location" {
  type        = string
  description = "Azure region of the workspace, for example `swedencentral`."
  nullable    = false
}

variable "name" {
  type        = string
  description = "Name of the Log Analytics workspace: 4 to 63 characters, letters, digits and hyphens, starting and ending with a letter or digit."
  nullable    = false

  validation {
    condition     = can(regex("^[A-Za-z0-9][A-Za-z0-9-]{2,61}[A-Za-z0-9]$", var.name))
    error_message = "`name` must be 4 to 63 characters: letters, digits and hyphens, starting and ending with a letter or digit."
  }
}

variable "parent_id" {
  type        = string
  description = "Resource ID of the resource group the workspace is created in."
  nullable    = false

  validation {
    condition     = can(provider::azapi::parse_resource_id("Microsoft.Resources/resourceGroups", var.parent_id))
    error_message = "`parent_id` must be a resource group resource ID."
  }
}

variable "daily_quota_gb" {
  type        = number
  default     = null
  description = "(Optional) Daily ingestion cap in GB. Ingestion stops for the rest of the day once it is reached. Defaults to `null`, no cap."

  validation {
    condition     = var.daily_quota_gb == null ? true : var.daily_quota_gb > 0
    error_message = "`daily_quota_gb` must be greater than 0, or null for no cap."
  }
}

variable "local_authentication_enabled" {
  type        = bool
  default     = false
  description = "Whether the workspace accepts data sent with its shared keys (the HTTP Data Collector API, legacy agents). Defaults to `false`: only Microsoft Entra ID, which the Azure Monitor Agent and diagnostic settings use."
  nullable    = false
}

variable "permanently_delete_on_destroy" {
  type        = bool
  default     = false
  description = "Whether destroying the workspace deletes it permanently. Defaults to `false`: Azure keeps a deleted workspace and its data recoverable for 14 days and reserves its name, and creating a workspace with the same name, resource group and region in that time recovers it."
  nullable    = false
}

variable "public_network_access_for_ingestion" {
  type        = string
  default     = "Enabled"
  description = "Whether the workspace accepts ingestion over public networks: `Enabled` (default) or `Disabled` (only through an Azure Monitor Private Link Scope)."
  nullable    = false

  validation {
    condition     = contains(["Enabled", "Disabled"], var.public_network_access_for_ingestion)
    error_message = "`public_network_access_for_ingestion` must be `Enabled` or `Disabled`."
  }
}

variable "public_network_access_for_query" {
  type        = string
  default     = "Enabled"
  description = "Whether the workspace accepts queries over public networks: `Enabled` (default) or `Disabled` (only through an Azure Monitor Private Link Scope)."
  nullable    = false

  validation {
    condition     = contains(["Enabled", "Disabled"], var.public_network_access_for_query)
    error_message = "`public_network_access_for_query` must be `Enabled` or `Disabled`."
  }
}

variable "resource_permissions_enabled" {
  type        = bool
  default     = true
  description = "Whether users with access to a resource can read its logs without access to the workspace (access control mode \"Use resource or workspace permissions\", Azure's default). Defaults to `true`."
  nullable    = false
}

variable "retention_in_days" {
  type        = number
  default     = 30
  description = "Default analytics retention of the workspace's tables, in days: 30 to 730. Defaults to `30`."
  nullable    = false

  validation {
    condition     = var.retention_in_days >= 30 && var.retention_in_days <= 730 && floor(var.retention_in_days) == var.retention_in_days
    error_message = "`retention_in_days` must be a whole number from 30 to 730."
  }
}

variable "data_collection_rules" {
  type = object({
    change_tracking = optional(object({
      name = string
    }))
    vm_insights = optional(object({
      name                               = string
      processes_and_dependencies_enabled = optional(bool, false)
    }))
    defender_sql = optional(object({
      name                           = string
      sql_queries_collection_enabled = optional(bool, false)
    }))
  })
  default     = {}
  description = <<DESCRIPTION
The data collection rules the Azure landing zone (ALZ) policies take, each created when named. They send to
the workspace and are created in its region. Defaults to none.

- `change_tracking` - (Optional) Change tracking and inventory for Windows and Linux (`Deploy-VM-ChangeTrack` and related policies).
  - `name` - Name of the rule.
- `vm_insights` - (Optional) VM insights performance counters (`Deploy-VM-Monitoring` and related policies).
  - `name` - Name of the rule.
  - `processes_and_dependencies_enabled` - (Optional) Also collect processes and dependencies for the VM insights Map, through the Dependency agent. Defaults to `false`, as VM insights does, to save ingestion cost.
- `defender_sql` - (Optional) Microsoft Defender for SQL on machines (`Deploy-MDFC-DefSQL-AMA`).
  - `name` - Name of the rule.
  - `sql_queries_collection_enabled` - (Optional) Collect SQL queries for security research. Defaults to `false`.
DESCRIPTION
  nullable    = false
}

variable "user_assigned_identity" {
  type = object({
    name = string
  })
  default     = null
  description = <<DESCRIPTION
(Optional) The user-assigned identity the Azure Monitor Agent uses (ALZ policies `Deploy-VM-ChangeTrack`,
`Deploy-VM-Monitoring`, `Deploy-MDFC-DefSQL-AMA` and related). Created in the workspace's resource group
and region. Defaults to `null`, none.

- `name` - Name of the identity.
DESCRIPTION
}
