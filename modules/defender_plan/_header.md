# Microsoft Defender for Cloud plan

One Microsoft Defender for Cloud plan on a subscription (`Microsoft.Security/pricings`). The root module
calls it for each entry of `defender_plans`; a separate state can call it alone:

```hcl
source = "git::https://github.com/fortytwoservices/az-tf-mlz-management.git//modules/defender_plan?ref=vX.Y.Z"
```

- **Not tested in Azure.** By decision, this is released without a sandbox test; the first customer
  deployment is its first test. `azapi_update_resource` does not validate its body against the AzAPI
  provider's schema, so the unit tests do, through an `azapi_resource` fixture (property names and types;
  the schema does not restrict the tier's values, which this module validates).
- Only what is set is managed: an unset `sub_plan` and the extensions not listed stay as Azure has them.
- A subscription's plans always exist, so the plan is updated in place (`azapi_update_resource`):
  `tier = "Free"` turns it off, and removing it from the configuration leaves Azure as it is (still on,
  if it was). Turn it off first, then remove it.
- A Standard plan bills every protected resource in the subscription.
- With the Azure landing zone policies, give each plan one owner: this module, or the
  `Deploy-MDFC-Config-H224` assignment's `enableAscFor*` parameters (`Disabled` by default), not both.
- No lock: a lock at subscription scope would lock the whole subscription.
