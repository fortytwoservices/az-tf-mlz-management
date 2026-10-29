resource "azapi_resource" "this" {
  type      = var.resource_types.insights_data_collection_rules
  name      = var.name
  parent_id = var.parent_id
  location  = var.location
  # Every data source kind and optional property is sent, null when unset, so that removing one reaches
  # Azure: azapi compares only the keys in the body. Maps become lists in key order.
  body = {
    properties = {
      description = var.description
      dataSources = {
        performanceCounters = length(var.data_sources.performance_counters) == 0 ? null : [for name, source in var.data_sources.performance_counters : {
          name                       = name
          streams                    = source.streams
          samplingFrequencyInSeconds = source.sampling_frequency_in_seconds
          counterSpecifiers          = source.counter_specifiers
        }]
        windowsEventLogs = length(var.data_sources.windows_event_logs) == 0 ? null : [for name, source in var.data_sources.windows_event_logs : {
          name         = name
          streams      = source.streams
          xPathQueries = source.x_path_queries
        }]
        syslog = length(var.data_sources.syslog) == 0 ? null : [for name, source in var.data_sources.syslog : {
          name          = name
          streams       = source.streams
          facilityNames = source.facility_names
          logLevels     = source.log_levels
        }]
        extensions = length(local.extensions) == 0 ? null : local.extensions
      }
      destinations = {
        logAnalytics = [for name, destination in var.log_analytics_destinations : {
          name                = name
          workspaceResourceId = destination.workspace_resource_id
        }]
      }
      dataFlows = [for _, flow in var.data_flows : {
        streams      = flow.streams
        destinations = flow.destinations
        transformKql = flow.transform_kql
        outputStream = flow.output_stream
      }]
    }
  }
  # Extension settings are free-form objects: a key removed from them leaves the remaining keys unchanged,
  # so azapi would plan no change. A new version sends the extensions again whenever they change, and the
  # PUT replaces what Azure holds.
  sensitive_body         = { properties = { dataSources = { extensions = length(local.extensions) == 0 ? null : local.extensions } } }
  sensitive_body_version = { "properties.dataSources.extensions" = sha256(jsonencode(local.extensions)) }
  ignore_body_changes    = length(var.ignore_body_changes.insights_data_collection_rules) > 0 ? var.ignore_body_changes.insights_data_collection_rules : null
  response_export_values = []
  retry                  = var.retry
  tags                   = var.tags

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]
    content {
      create = timeouts.value.create
      read   = timeouts.value.read
      update = timeouts.value.update
      delete = timeouts.value.delete
    }
  }
}
