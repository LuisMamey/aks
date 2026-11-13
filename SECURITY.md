# Security Policy: Azure Kubernetes Service (AKS) Platform

## Supported Versions

Only the latest release on the `main` branch is actively supported with security updates and configuration patches.

| Version | Supported          |
| ------- | ------------------ |
| 1.0.x   | :white_check_mark: |
| < 1.0.0 | :x:                |

---

## Security Principles in this Repository

1. **Zero Secrets in Code and Pods:** All authentication is delegated to Microsoft Entra ID via **Azure Workload Identity** and short-lived OIDC federated tokens. No static service principal credentials, secrets, or certificates are stored in Git or Kubernetes manifests.
2. **Shift-Left Static Analysis:** Every pull request is evaluated against:
   - **Checkov (IaC SAST):** Scans Terraform for CIS benchmarks and security standards.
   - **Gitleaks:** Secret detection across the complete Git commit history.
   - **OpenSSF Scorecard:** Supply-chain security assessment ensuring pinned dependencies and least-privilege tokens.
3. **Formal Architectural Governance:** Any deviation or risk acceptance is formally recorded in an **Architecture Decision Record (ADR)** under `docs/adr/`.

---

## Reporting a Vulnerability

We take the security of this infrastructure platform seriously. If you discover a vulnerability or potential misconfiguration, please report it responsibly:

1. **Do NOT open a public GitHub issue.**
2. Submit a confidential report via [GitHub Private Security Advisories](https://github.com/LuisMamey/aks/security/advisories/new).
3. Provide a clear description of the vulnerability, affected files or Terraform resources, and steps to reproduce.

### Response Timeframes
* **Initial Triage:** Within 48 hours.
* **Remediation & Patch:** Critical vulnerabilities are addressed within 7 days.
