# Microsoft Sentinel onboarding

Onboards Microsoft Sentinel on a Log Analytics workspace: the workspace's onboarding state
(`Microsoft.SecurityInsights/onboardingStates`, always named `default`). The workspace submodule calls it
when `sentinel_onboarding` is set; a separate state can call it alone with a workspace ID:

```hcl
source = "git::https://github.com/fortytwoservices/az-tf-mlz-management.git//modules/sentinel_onboarding?ref=vX.Y.Z"
```

- **Not tested in Azure.** By decision, this is released without a sandbox test; the first customer
  deployment is its first test. Only its body is checked, against the AzAPI provider's schema.
- Sentinel bills the data it analyses in the workspace. Removing this offboards Sentinel from the workspace.
- `customer_managed_key_enabled` needs the workspace on a dedicated cluster with a customer-managed key;
  set it at onboarding.
- No lock of its own: a lock on the workspace covers it. When the workspace submodule calls it, the
  workspace's lock is removed around changes to it.
