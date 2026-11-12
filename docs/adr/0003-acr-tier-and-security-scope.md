# ADR 0003: Azure Container Registry (ACR) Tier and Security Scope

## Status
Accepted

## Context
Checkov policy suite flags eight controls against the Azure Container Registry in `terraform/acr.tf`:
- `CKV_AZURE_165`: geo-replicated container registries across multiple regions.
- `CKV_AZURE_233`: zone-redundant storage.
- `CKV_AZURE_139`: disable public network access.
- `CKV_AZURE_237`: enable dedicated data endpoints.
- `CKV_AZURE_167`: configure untagged manifest retention policy.
- `CKV_AZURE_164`: enforce Docker Content Trust / signed images.
- `CKV_AZURE_163`: enable continuous vulnerability scanning.
- `CKV_AZURE_166`: enable image quarantine and verification.

## Decision
We deliberately accept provisioning ACR under the **Basic SKU** (`admin_enabled = false`) and suppressing these eight controls for this environment:

- **Cost & SKU Tier Constraints (`CKV_AZURE_165`, `CKV_AZURE_233`, `CKV_AZURE_139`, `CKV_AZURE_237`, `CKV_AZURE_167`, `CKV_AZURE_164`):** Features like geo-replication, Availability Zone redundancy, private endpoints / firewall rules, dedicated data endpoints, manifest retention policies, and Docker Content Trust require the **Premium SKU** (~$50 USD/month vs. ~$5 USD/month for Basic). For single-region development and lab workloads, the Basic tier provides full container image storage and native AKS integration via Azure RBAC (`AcrPull`) without excessive enterprise licensing overhead.
- **Public Network Access (`CKV_AZURE_139`):** Local CLI and CI runners require HTTPS connectivity to push built images without deploying dedicated Site-to-Site VPN gateways, ExpressRoute, or self-hosted runners within the virtual network. Inbound access is strictly authenticated via Azure Entra ID OAuth tokens; legacy admin credentials (`admin_enabled = false`) are permanently disabled.
- **Vulnerability Scanning & Quarantine (`CKV_AZURE_163`, `CKV_AZURE_166`):** Native ACR vulnerability assessment requires provisioning **Microsoft Defender for Cloud (Defender for Containers)** at a per-node monthly subscription fee. Container image scanning and SBOM verification are shifted left and handled directly within GitHub Actions pipelines (using tools like Trivy, Grype, and Cosign) prior to registry ingestion.

## Consequences
- **Positive:** Minimizes cloud spend (~10x cost reduction compared to Premium tier), enforces passwordless RBAC authentication (`AcrPull`), and aligns vulnerability scanning with shift-left CI practices.
- **Negative / Accepted Risk:** Registry is hosted in a single Azure region without multi-AZ storage redundancy, and public HTTPS endpoint remains accessible to authenticated Entra ID principals.
- **Suppression:** Suppressed via `#checkov:skip=<rule>:Accepted risk — see docs/adr/0003-acr-tier-and-security-scope.md` across `terraform/acr.tf`.
