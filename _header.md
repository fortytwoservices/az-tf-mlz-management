# az-tf-mlz-management

The management resources of a Fortytwo managed landing zone (MLZ), in AzAPI: a Log Analytics workspace,
the three data collection rules the Azure landing zone (ALZ) policies take, and the Azure Monitor Agent's
user-assigned identity. It replaces `avm-ptn-alz-management` and AVM's Log Analytics module.

```hcl
module "management" {
  source = "git::https://github.com/fortytwoservices/az-tf-mlz-management.git?ref=vX.Y.Z"

  name      = "law-management"
  parent_id = "/subscriptions/<subscription>/resourceGroups/rg-management"
  location  = "swedencentral"
  data_collection_rules = {
    change_tracking = { name = "dcr-change-tracking" }
    vm_insights     = { name = "dcr-vm-insights" }
    defender_sql    = { name = "dcr-defender-sql" }
  }
  user_assigned_identity = { name = "id-ama" }
  lock                   = { kind = "CanNotDelete" }
}
```

## What it creates

- **The workspace** (`modules/log_analytics_workspace`), always, on the `PerGB2018` pricing tier: 30 days
  of retention by default, no daily cap, local authentication (shared keys) off, resource-context access
  on, public ingestion and query on. Role assignments and diagnostic settings go on the workspace.
- **The legacy solutions whose tables the rules send to:** `ChangeTracking` with the change tracking rule,
  `SQLAdvancedThreatProtection` and `SQLVulnerabilityAssessment` with the Defender for SQL rule. Azure
  refuses a rule whose destination table does not exist (`InvalidOutputTable`), and a solution adds its
  tables about a minute after it is created, so `retry` retries that error by default.
- **The data collection rules** (`modules/data_collection_rule`), each when named, in the workspace's
  region and sending to it, with the bodies of `avm-ptn-alz-management`: change tracking and inventory for
  Windows and Linux; VM insights performance counters, with processes and dependencies (the Map) only when
  `processes_and_dependencies_enabled` is set; Microsoft Defender for SQL on machines.
- **The identity** (`modules/user_assigned_identity`), when named.
- **The lock** goes on every resource the module creates.

The outputs give what `avm-ptn-alz`'s `policy_default_values` take: `resource_id`
(`log_analytics_workspace_id`), `data_collection_rule_resource_ids` (`change_tracking`, `vm_insights`,
`defender_sql`) and `user_assigned_identity` (`resource_id`, `name`). That input takes each value as
`jsonencode({ value = ... })`; `examples/default` builds the map.

Not created: the resource group, an automation account and its linked service (Azure Update Manager and
change tracking with the Azure Monitor Agent need none), other legacy solutions (VM insights with the
Azure Monitor Agent needs none, the Map included), Microsoft Sentinel and Defender for Cloud plans. Associations between machines
and the rules are left to the ALZ policies.

## Behaviour to know

- **Soft delete.** A deleted workspace is kept for 14 days and its name stays reserved; creating a
  workspace with the same name, resource group and region in that time recovers it with its data.
  `permanently_delete_on_destroy = true` deletes it permanently instead (development and tests).
- **ALZ denies deleting the identity** (`DenyAction-DeleteUAMIAMA`): where that policy is assigned,
  removing or renaming `user_assigned_identity` fails until the policy is exempted.
- **A `ReadOnly` lock** blocks updates of the locked resources themselves: remove it before changing them.
- Every submodule can be called alone, for example a workload's own data collection rule:
  `source = "git::https://github.com/fortytwoservices/az-tf-mlz-management.git//modules/data_collection_rule?ref=vX.Y.Z"`.
