# Log Analytics workspace

A Log Analytics workspace (`Microsoft.OperationalInsights/workspaces`) on the pay-as-you-go `PerGB2018`
pricing tier, with an optional lock, role assignments and diagnostic settings through
`az-tf-mlz-interfaces`. The root module creates the management workspace with it; a separate state can
call this submodule alone:

```hcl
source = "git::https://github.com/fortytwoservices/az-tf-mlz-management.git//modules/log_analytics_workspace?ref=vX.Y.Z"
```

- `solutions` adds legacy solutions (`Microsoft.OperationsManagement/solutions`), for the tables some data
  collection rules send to: `ChangeTracking` for change tracking, `SQLAdvancedThreatProtection` and
  `SQLVulnerabilityAssessment` for Defender for SQL. Each is named `<product>(<workspace>)` and follows
  the workspace. The `resource_id` output is known once they exist, so rules that use it come after them.
- Local authentication (the workspace's shared keys) is off by default: the Azure Monitor Agent and
  diagnostic settings use Microsoft Entra ID.
- A deleted workspace is kept for 14 days and its name stays reserved; creating a workspace with the same
  name, resource group and region in that time recovers it with its data. Set
  `permanently_delete_on_destroy` to delete it permanently instead (development and tests).
- A `ReadOnly` lock blocks updates of the workspace itself: remove it first.
