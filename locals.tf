locals {
  data_collection_rule_names = { for kind, rule in var.data_collection_rules : kind => rule.name if rule != null }

  # The legacy solutions whose tables the rules send to; Azure refuses a rule whose table is missing
  # (InvalidOutputTable, sandbox 2026-10-28). VM insights needs none.
  solutions = setunion(
    var.data_collection_rules.change_tracking == null ? [] : ["ChangeTracking"],
    var.data_collection_rules.defender_sql == null ? [] : ["SQLAdvancedThreatProtection", "SQLVulnerabilityAssessment"],
  )

  # The rules the Azure landing zone policies take, with the bodies of avm-ptn-alz-management v0.9.0 (MIT).
  # Each sends to the workspace through its one destination.
  data_collection_rules = {
    change_tracking = {
      description = "Data collection rule for CT"
      destination = "Microsoft-CT-Dest"
      data_sources = {
        extensions = {
          CTDataSource-Windows = {
            extension_name = "ChangeTracking-Windows"
            streams        = local.change_tracking_streams
            extension_settings = jsonencode({
              enableFiles     = true
              enableSoftware  = true
              enableRegistry  = true
              enableServices  = true
              enableInventory = true
              registrySettings = {
                registryCollectionFrequency = 3600
                registryInfo = [for index, key in local.change_tracking_registry_keys : {
                  name        = "Registry_${index + 1}"
                  groupTag    = "Recommended"
                  enabled     = false
                  recurse     = true
                  description = ""
                  keyName     = key
                  valueName   = ""
                }]
              }
              fileSettings      = { fileCollectionFrequency = 2700 }
              softwareSettings  = { softwareCollectionFrequency = 1800 }
              inventorySettings = { inventoryCollectionFrequency = 36000 }
              servicesSettings  = { serviceCollectionFrequency = 1800 }
            })
          }
          CTDataSource-Linux = {
            extension_name = "ChangeTracking-Linux"
            streams        = local.change_tracking_streams
            extension_settings = jsonencode({
              enableFiles     = true
              enableSoftware  = true
              enableRegistry  = false
              enableServices  = true
              enableInventory = true
              fileSettings = {
                fileCollectionFrequency = 900
                fileInfo = [{
                  name                  = "ChangeTrackingLinuxPath_default"
                  enabled               = true
                  destinationPath       = "/etc/.*.conf"
                  useSudo               = true
                  recurse               = true
                  maxContentsReturnable = 5000000
                  pathType              = "File"
                  type                  = "File"
                  links                 = "Follow"
                  maxOutputSize         = 500000
                  groupTag              = "Recommended"
                }]
              }
              softwareSettings  = { softwareCollectionFrequency = 300 }
              inventorySettings = { inventoryCollectionFrequency = 36000 }
              servicesSettings  = { serviceCollectionFrequency = 300 }
            })
          }
        }
      }
      data_flows = {
        change_tracking = { streams = local.change_tracking_streams, destinations = ["Microsoft-CT-Dest"] }
      }
    }

    # Microsoft Learn's classic logs-based VM insights rule. Processes and dependencies (the Map) come from
    # the Dependency agent's extension data source, off unless asked for.
    vm_insights = {
      description = "Data collection rule for VM Insights."
      destination = "VMInsightsPerf-Logs-Dest"
      data_sources = {
        performance_counters = {
          VMInsightsPerfCounters = {
            streams                       = ["Microsoft-InsightsMetrics"]
            sampling_frequency_in_seconds = 60
            counter_specifiers            = ["\\VmInsights\\DetailedMetrics"]
          }
        }
        extensions = merge({}, local.vm_insights_processes_and_dependencies ? {
          DependencyAgentDataSource = { extension_name = "DependencyAgent", streams = ["Microsoft-ServiceMap"] }
        } : null)
      }
      data_flows = merge(
        { insights_metrics = { streams = ["Microsoft-InsightsMetrics"], destinations = ["VMInsightsPerf-Logs-Dest"] } },
        local.vm_insights_processes_and_dependencies ? {
          service_map = { streams = ["Microsoft-ServiceMap"], destinations = ["VMInsightsPerf-Logs-Dest"] }
        } : null,
      )
    }

    defender_sql = {
      description = "Data collection rule for Defender for SQL."
      destination = "LogAnalyticsDest"
      data_sources = {
        extensions = {
          MicrosoftDefenderForSQL = {
            extension_name = "MicrosoftDefenderForSQL"
            streams        = local.defender_sql_streams
            extension_settings = jsonencode({
              enableCollectionOfSqlQueriesForSecurityResearch = local.defender_sql_queries_collection
            })
          }
        }
      }
      data_flows = {
        defender_sql = { streams = local.defender_sql_streams, destinations = ["LogAnalyticsDest"] }
      }
    }
  }

  change_tracking_streams = ["Microsoft-ConfigurationChange", "Microsoft-ConfigurationChangeV2", "Microsoft-ConfigurationData"]
  change_tracking_registry_keys = [
    "HKEY_LOCAL_MACHINE\\Software\\Microsoft\\Windows\\CurrentVersion\\Group Policy\\Scripts\\Startup",
    "HKEY_LOCAL_MACHINE\\Software\\Microsoft\\Windows\\CurrentVersion\\Group Policy\\Scripts\\Shutdown",
    "HKEY_LOCAL_MACHINE\\SOFTWARE\\Wow6432Node\\Microsoft\\Windows\\CurrentVersion\\Run",
    "HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Active Setup\\Installed Components",
    "HKEY_LOCAL_MACHINE\\Software\\Classes\\Directory\\ShellEx\\ContextMenuHandlers",
    "HKEY_LOCAL_MACHINE\\Software\\Classes\\Directory\\Background\\ShellEx\\ContextMenuHandlers",
    "HKEY_LOCAL_MACHINE\\Software\\Classes\\Directory\\Shellex\\CopyHookHandlers",
    "HKEY_LOCAL_MACHINE\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\ShellIconOverlayIdentifiers",
    "HKEY_LOCAL_MACHINE\\Software\\Wow6432Node\\Microsoft\\Windows\\CurrentVersion\\Explorer\\ShellIconOverlayIdentifiers",
    "HKEY_LOCAL_MACHINE\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Browser Helper Objects",
    "HKEY_LOCAL_MACHINE\\Software\\Wow6432Node\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Browser Helper Objects",
    "HKEY_LOCAL_MACHINE\\Software\\Microsoft\\Internet Explorer\\Extensions",
    "HKEY_LOCAL_MACHINE\\Software\\Wow6432Node\\Microsoft\\Internet Explorer\\Extensions",
    "HKEY_LOCAL_MACHINE\\Software\\Microsoft\\Windows NT\\CurrentVersion\\Drivers32",
    "HKEY_LOCAL_MACHINE\\Software\\Wow6432Node\\Microsoft\\Windows NT\\CurrentVersion\\Drivers32",
    "HKEY_LOCAL_MACHINE\\System\\CurrentControlSet\\Control\\Session Manager\\KnownDlls",
    "HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Winlogon\\Notify",
  ]
  defender_sql_streams = [
    "Microsoft-DefenderForSqlAlerts",
    "Microsoft-DefenderForSqlLogins",
    "Microsoft-DefenderForSqlTelemetry",
    "Microsoft-DefenderForSqlScanEvents",
    "Microsoft-DefenderForSqlScanResults",
    "Microsoft-SqlAtpStatus-DefenderForSql",
  ]
  defender_sql_queries_collection        = var.data_collection_rules.defender_sql == null ? false : var.data_collection_rules.defender_sql.sql_queries_collection_enabled
  vm_insights_processes_and_dependencies = var.data_collection_rules.vm_insights == null ? false : var.data_collection_rules.vm_insights.processes_and_dependencies_enabled
}
