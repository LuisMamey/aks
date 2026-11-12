# ADR 0002: AKS Cluster Security & Cost Scope

## Status
Accepted

## Context
Checkov policy suite flags thirteen controls against the AKS cluster in `terraform/aks.tf`. Six controls (`CKV_AZURE_171`, `CKV_AZURE_116`, `CKV_AZURE_172`, `CKV_AZURE_7`, `CKV_AZURE_168`, and `CKV_AZURE_226`) are remediated directly in code (automatic `patch` upgrade channel, Azure Policy add-on, Secrets Store CSI secret autorotation, Azure Network Policy, `max_pods = 50`, and `Ephemeral` OS disk on `Standard_D2ds_v6`).

The remaining seven controls are flagged against `azurerm_kubernetes_cluster.aks`:
- `CKV_AZURE_170`: use the Paid/Standard SKU for SLA.
- `CKV_AZURE_115`: enable private cluster.
- `CKV_AZURE_6`: configure API Server Authorized IP Ranges.
- `CKV_AZURE_232`: restrict system node pool to critical system pods only.
- `CKV_AZURE_141`: disable AKS local admin account.
- `CKV_AZURE_117`: encrypt node disks with a Disk Encryption Set (CMK).
- `CKV_AZURE_227`: enable encryption at host.

## Decision
We deliberately accept suppressing these seven controls for the AKS learning/lab environment:

- **Free Control Plane SKU (`CKV_AZURE_170`):** `sku_tier = "Free"` keeps control plane cost at $0 while preserving full Kubernetes functionality. Production workloads requiring financially backed 99.95% uptime SLA would switch to `"Standard"`.
- **Public API Endpoint & Authorized IP Ranges (`CKV_AZURE_115`, `CKV_AZURE_6`):** Enabling a private cluster requires a VPN Gateway or Bastion host inside the VNet for `kubectl` access. Likewise, hardcoding a developer's dynamic residential IP in `authorized_ip_ranges` leaks personal network metadata in a public repository and breaks CLI access on IP rotation. API access remains protected by TLS and Kubernetes RBAC.
- **Single System Node Pool (`CKV_AZURE_232`):** Enforcing `only_critical_addons_enabled = true` requires provisioning a separate user node pool, doubling compute instances and risking the 4-vCPU Free Trial regional quota.
- **Local Admin Account (`CKV_AZURE_141`):** Retained temporarily for direct `az aks get-credentials` workflows prior to configuring Entra ID RBAC groups and `kubelogin` federation.
- **Platform-Managed Disk Encryption (`CKV_AZURE_117`, `CKV_AZURE_227`):** Ephemeral OS disks are encrypted at rest by Azure platform-managed keys. Dedicated Disk Encryption Sets (Key Vault CMK) and subscription-level `EncryptionAtHost` feature registration add cost and bootstrap prerequisites outside this lab's scope.

## Consequences
- **Positive:** Achieves Network Policy enforcement, ephemeral NVMe/local OS disks, Azure Policy guardrails, and automatic security patching while staying within the 4-vCPU Free Trial quota.
- **Negative / Accepted Risk:** Control plane has no paid SLA, API server endpoint is publicly reachable over TLS, and node OS disks use platform-managed encryption.
- **Suppression:** Suppressed via `#checkov:skip=<rule>:Accepted risk — see docs/adr/0002-aks-security-scope.md` in `terraform/aks.tf`.
