# ADR 0001: Terraform Remote State Backend Hardening Scope

## Status
Accepted

## Context
Checkov policy suite flags ten controls against the Terraform remote state bootstrap infrastructure in `bootstrap/main.tf`. Four controls (`CKV_AZURE_44`, `CKV_AZURE_206`, `CKV2_AZURE_38`, and `CKV2_AZURE_41`) are remediated directly in code (enforcing TLS 1.2, geo-redundant `GRS` replication, 7-day blob/container soft-delete, and a 1-hour SAS expiration policy).

The remaining six controls are flagged across `azurerm_storage_account.tfstate` and `azurerm_storage_container.tfstate`:
- `azurerm_storage_account.tfstate`:
  - `CKV_AZURE_59`: disallow public network access.
  - `CKV2_AZURE_33`: configure a Private Endpoint.
  - `CKV2_AZURE_40`: disable Shared Key authorization.
  - `CKV2_AZURE_1`: encrypt critical data with a Customer-Managed Key (CMK).
  - `CKV_AZURE_33`: enable Queue service request logging.
- `azurerm_storage_container.tfstate`:
  - `CKV2_AZURE_21`: enable Blob service read request logging.

## Decision
We deliberately accept suppressing these six controls for the bootstrap state backend in this lab environment:

- **Public Network Access & Private Endpoint (`CKV_AZURE_59`, `CKV2_AZURE_33`):** Terraform is executed from a local developer workstation without a Site-to-Site VPN or ExpressRoute into an Azure VNet. Disabling public network access or enforcing a Private Endpoint would block `terraform init`, `plan`, and `apply` from local CLI workflows. Blob container access remains strictly `private` and TLS 1.2 encrypted.
- **Shared Key Authorization (`CKV2_AZURE_40`):** Shared Key authentication is temporarily retained for `bootstrap/` state operations prior to provisioning dedicated Entra ID `Storage Blob Data Contributor` RBAC assignments and OIDC federation.
- **Customer-Managed Key (`CKV2_AZURE_1`):** Azure Storage encrypts all state data at rest natively with Microsoft-managed AES-256 keys (`Storage Service Encryption`). Provisioning an Azure Key Vault and CMK rotation workflow for a bootstrap state account introduces additional cost and circular dependency complexity.
- **Queue & Blob Read Logging (`CKV_AZURE_33`, `CKV2_AZURE_21`):** Queue Storage is completely unused by Terraform state, and diagnostic Blob read logging requires a pre-existing Log Analytics Workspace, which belongs to the main infrastructure stack (`terraform/monitoring.tf`) rather than `bootstrap/`. Management-plane operations remain audited via Azure Activity Logs.

## Consequences
- **Positive:** Protects state files with TLS 1.2, `GRS` geo-redundancy, 7-day soft-delete recovery, and private container access while keeping local Terraform workflows functional.
- **Negative / Accepted Risk:** The Storage Account endpoint remains reachable over HTTPS from authenticated clients without a Private Endpoint, and Shared Key auth remains enabled until Entra ID RBAC/OIDC is introduced.
- **Suppression:** Suppressed via `#checkov:skip=<rule>:Accepted risk — see docs/adr/0001-bootstrap-state-hardening-scope.md` in `bootstrap/main.tf`.
