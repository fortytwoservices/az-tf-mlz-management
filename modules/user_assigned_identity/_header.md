# User-assigned identity

A user-assigned managed identity (`Microsoft.ManagedIdentity/userAssignedIdentities`), with an optional
lock and role assignments through `az-tf-mlz-interfaces`. The root module creates it for the Azure
Monitor Agent; a separate state can call this submodule alone:

```hcl
source = "git::https://github.com/fortytwoservices/az-tf-mlz-management.git//modules/user_assigned_identity?ref=vX.Y.Z"
```

A `ReadOnly` lock blocks updates of the identity itself (tags, isolation scope): remove it first.
