# Data collection rule

A data collection rule (`Microsoft.Insights/dataCollectionRules`) that sends what the Azure Monitor Agent
collects to Log Analytics workspaces, with an optional lock, role assignments and diagnostic settings
through `az-tf-mlz-interfaces`. The root module creates the three rules the Azure landing zone policies
take; a separate state can call this submodule alone for its own rules:

```hcl
source = "git::https://github.com/fortytwoservices/az-tf-mlz-management.git//modules/data_collection_rule?ref=vX.Y.Z"
```

- Data sources: performance counters, Windows event logs, syslog and VM extensions. Extension settings are
  passed as JSON (`jsonencode`). Destinations: Log Analytics workspaces.
- The rule must be in the region of its Log Analytics workspace.
- Associations between machines and the rule are not created here: Azure Policy or the workload does that.
- A `ReadOnly` lock blocks updates of the rule itself: remove it first.
