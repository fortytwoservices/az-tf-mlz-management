variable "location" {
  type        = string
  description = "Azure region of the data collection rule, for example `swedencentral`. A rule for the Azure Monitor Agent goes in the region of its Log Analytics workspace."
  nullable    = false
}

variable "name" {
  type        = string
  description = "Name of the data collection rule."
  nullable    = false
}

variable "parent_id" {
  type        = string
  description = "Resource ID of the resource group the data collection rule is created in."
  nullable    = false

  validation {
    condition     = can(provider::azapi::parse_resource_id("Microsoft.Resources/resourceGroups", var.parent_id))
    error_message = "`parent_id` must be a resource group resource ID."
  }
}

variable "data_flows" {
  type = map(object({
    streams       = list(string)
    destinations  = list(string)
    transform_kql = optional(string)
    output_stream = optional(string)
  }))
  description = <<DESCRIPTION
Data flows, keyed by a stable name of your choice (Azure stores no name; the flows are sent in key order).
Each sends streams to destinations.

- `streams` - Streams to send, for example `["Microsoft-Perf"]`.
- `destinations` - Destination names: keys of `log_analytics_destinations`.
- `transform_kql` - (Optional) KQL transformation of the stream data, for example `source | where Level == "Error"`.
- `output_stream` - (Optional) Output stream of the transformation, when it writes to a different table.
DESCRIPTION
  nullable    = false

  validation {
    condition     = length(var.data_flows) > 0
    error_message = "A data collection rule needs at least one data flow."
  }
  validation {
    condition     = alltrue([for _, flow in var.data_flows : length(flow.streams) > 0 && length(flow.destinations) > 0])
    error_message = "Each data flow needs at least one stream and one destination."
  }
  validation {
    condition     = alltrue(flatten([for _, flow in var.data_flows : [for destination in flow.destinations : contains(keys(var.log_analytics_destinations), destination)]]))
    error_message = "Each data flow destination must be a key of `log_analytics_destinations`."
  }
}

variable "log_analytics_destinations" {
  type = map(object({
    workspace_resource_id = string
  }))
  description = <<DESCRIPTION
Log Analytics workspaces the rule sends data to, keyed by destination name (the name data flows refer to).

- `workspace_resource_id` - Resource ID of the Log Analytics workspace.
DESCRIPTION
  nullable    = false

  validation {
    condition     = length(var.log_analytics_destinations) > 0
    error_message = "A data collection rule needs at least one destination."
  }
  validation {
    condition     = alltrue([for _, destination in var.log_analytics_destinations : can(provider::azapi::parse_resource_id("Microsoft.OperationalInsights/workspaces", destination.workspace_resource_id))])
    error_message = "Each `workspace_resource_id` must be a Log Analytics workspace resource ID."
  }
}

variable "data_sources" {
  type = object({
    performance_counters = optional(map(object({
      streams                       = list(string)
      sampling_frequency_in_seconds = number
      counter_specifiers            = list(string)
    })), {})
    windows_event_logs = optional(map(object({
      streams        = list(string)
      x_path_queries = list(string)
    })), {})
    syslog = optional(map(object({
      streams        = list(string)
      facility_names = list(string)
      log_levels     = list(string)
    })), {})
    extensions = optional(map(object({
      extension_name     = string
      streams            = list(string)
      extension_settings = optional(string)
      input_data_sources = optional(list(string), [])
    })), {})
  })
  default     = {}
  description = <<DESCRIPTION
Data sources the Azure Monitor Agent collects, each a map keyed by data source name. Names must be unique across all kinds. Defaults to none (a rule for direct ingestion).

- `performance_counters` - Performance counters.
  - `streams` - Streams to send the counters to, for example `["Microsoft-Perf"]`.
  - `sampling_frequency_in_seconds` - Seconds between samples.
  - `counter_specifiers` - Counters, for example `["\\Processor(_Total)\\% Processor Time"]`.
- `windows_event_logs` - Windows event logs.
  - `streams` - For example `["Microsoft-Event"]`.
  - `x_path_queries` - XPath queries, for example `["System!*[System[(Level=1 or Level=2)]]"]`.
- `syslog` - Syslog.
  - `streams` - For example `["Microsoft-Syslog"]`.
  - `facility_names` - Facilities, for example `["auth", "daemon"]`, or `["*"]`.
  - `log_levels` - Levels, for example `["Warning", "Error", "Critical", "Alert", "Emergency"]`, or `["*"]`.
- `extensions` - VM extension data sources (change tracking, Defender for SQL, the Dependency agent).
  - `extension_name` - Name of the VM extension, for example `ChangeTracking-Windows`.
  - `streams` - Streams the extension sends.
  - `extension_settings` - (Optional) The extension's settings as JSON, for example `jsonencode({ enableFiles = true })`.
  - `input_data_sources` - (Optional) Names of the data sources the extension reads from.
DESCRIPTION
  nullable    = false

  validation {
    condition = length(concat(
      keys(var.data_sources.performance_counters), keys(var.data_sources.windows_event_logs),
      keys(var.data_sources.syslog), keys(var.data_sources.extensions),
      )) == length(distinct(concat(
        keys(var.data_sources.performance_counters), keys(var.data_sources.windows_event_logs),
        keys(var.data_sources.syslog), keys(var.data_sources.extensions),
    )))
    error_message = "Data source names must be unique across all kinds of data sources."
  }
  validation {
    condition     = alltrue([for _, extension in var.data_sources.extensions : extension.extension_settings == null ? true : can(jsondecode(extension.extension_settings))])
    error_message = "Each `extension_settings` must be JSON, for example `jsonencode({ ... })`."
  }
  validation {
    condition     = alltrue([for _, counter in var.data_sources.performance_counters : counter.sampling_frequency_in_seconds >= 1])
    error_message = "Each `sampling_frequency_in_seconds` must be at least 1."
  }
}

variable "description" {
  type        = string
  default     = null
  description = "(Optional) Description of the data collection rule."
}
