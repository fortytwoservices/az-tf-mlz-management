# Data collection rule example

The `data_collection_rule` and `log_analytics_workspace` submodules called alone, as a workload's state
would: a workspace, then a rule that collects Windows errors and warnings (keeping only errors through a
transformation), Linux authentication logs and two performance counters, with its error logs sent to the
workspace.

Run it with `scripts/e2e.sh examples/data_collection_rule`: apply, a second plan that must be empty,
destroy. The workspace is deleted permanently, as an example rebuilt on every run.
