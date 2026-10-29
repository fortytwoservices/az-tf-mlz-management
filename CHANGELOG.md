# Changelog

## [0.2.0](https://github.com/fortytwoservices/az-tf-mlz-management/compare/v0.1.1...v0.2.0) (2026-10-29)


### ⚠ BREAKING CHANGES

* `//modules/user_assigned_identity` is removed. A caller of it switches its `source` to `git::https://github.com/fortytwoservices/az-tf-mlz-user-assigned-identity.git?ref=v0.1.0`, with the same inputs and outputs; the state addresses are the same, so the deployed identity is not replaced.

### Code Refactoring

* use az-tf-mlz-user-assigned-identity for the agent identity ([#5](https://github.com/fortytwoservices/az-tf-mlz-management/issues/5)) ([99e2397](https://github.com/fortytwoservices/az-tf-mlz-management/commit/99e23974cd54ccfad578cec861f5296c0dc9ae06))

## [0.1.1](https://github.com/fortytwoservices/az-tf-mlz-management/compare/v0.1.0...v0.1.1) (2026-10-29)


### Features

* Microsoft Sentinel onboarding and Microsoft Defender for Cloud plans ([#3](https://github.com/fortytwoservices/az-tf-mlz-management/issues/3)) ([d9c51de](https://github.com/fortytwoservices/az-tf-mlz-management/commit/d9c51dea772095143028dcb96ec61bc7ccab35ab))

## 0.1.0 (2026-10-29)


### Features

* Log Analytics workspace, the ALZ data collection rules and the Azure Monitor Agent identity ([#1](https://github.com/fortytwoservices/az-tf-mlz-management/issues/1)) ([05b9771](https://github.com/fortytwoservices/az-tf-mlz-management/commit/05b97717f45657d9bd726eab8c80fdcdf4ea59d5))
