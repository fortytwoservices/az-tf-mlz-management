# Default example

The management resources of an Azure landing zone: a resource group, then a Log Analytics workspace that
sends its own audit logs and metrics to itself, the three data collection rules the ALZ policies take
(change tracking, VM insights with processes and dependencies, Defender for SQL) and the Azure Monitor
Agent's user-assigned identity, all under one `CanNotDelete` lock. The `policy_default_values` output is
`avm-ptn-alz`'s input of that name, ready to pass (each value `jsonencode({ value = ... })`).

Run it with `scripts/e2e.sh examples/default`: apply, a second plan that must be empty, destroy. The
destroyed workspace stays soft-deleted for 14 days; every run uses new names.
