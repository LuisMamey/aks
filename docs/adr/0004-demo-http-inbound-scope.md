# ADR 0004: Public Inbound HTTP Scope for Demo Workload

## Status
Accepted

## Context
Checkov policy suite flags rule `CKV_AZURE_160` ("Ensure that HTTP (port 80) access is restricted from the internet") against `azurerm_network_security_group.aks` in `terraform/network.tf` due to rule `AllowHttpInbound` permitting destination port `80` from `*` (the internet).

## Decision
We deliberately accept permitting inbound HTTP on port 80 and suppressing `CKV_AZURE_160` for this lab environment:

- **Public Demonstration & Metrics Ingestion:** The lab requires demonstrating public application accessibility and telemetry generation via a standard Azure Public Load Balancer (`demo-store-svc`) without provisioning custom domain names, public DNS zone delegation, or TLS certificates (Let's Encrypt / Cert-Manager).
- **Production Architecture Alignment:** In a production deployment, port 80 is either restricted to redirect to port 443 (TLS termination at an Application Gateway or Azure Front Door with Web Application Firewall), or restricted via Private Endpoints. For a transient demonstration workload, plain HTTP enables immediate verification of the LoadBalancer and Container Insights telemetry.

## Consequences
- **Positive:** Enables instant public connectivity to verify the AKS LoadBalancer service and stream real-time metrics into Azure Monitor without requiring custom domain registration or ACM/Key Vault certificates.
- **Negative / Accepted Risk:** Traffic over port 80 is unencrypted across the public internet.
- **Suppression:** Suppressed via `#checkov:skip=CKV_AZURE_160:Accepted risk — see docs/adr/0004-demo-http-inbound-scope.md` on `azurerm_network_security_group.aks` in `terraform/network.tf`.
