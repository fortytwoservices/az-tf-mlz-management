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

variable "solutions" {
  type        = set(string)
  default     = []
  description = "Legacy solutions to add to the workspace, by Microsoft gallery product name, for example `ChangeTracking` (`OMSGallery/ChangeTracking`). Some data collection rules need the tables a solution adds: `ChangeTracking` for change tracking, `SQLAdvancedThreatProtection` and `SQLVulnerabilityAssessment` for Defender for SQL. Defaults to none."
  nullable    = false

  validation {
    condition     = alltrue([for product in var.solutions : can(regex("^[A-Za-z0-9]+$", product))])
    error_message = "Each solution must be a gallery product name without its `OMSGallery/` prefix, for example `ChangeTracking`."
  }
}
