# My Azure Infrastructure

Personal Azure environment provisioned with Terraform, following a **CAF-Lite** (Cloud Adoption Framework — Lite) approach optimized for personal/individual use. CI/CD is automated via GitHub Actions with OIDC — no stored secrets.

## CAF-Lite Framework

This project implements a lightweight version of the [Azure Cloud Adoption Framework](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/) covering all key pillars with cost-free or near-free services:

| CAF Pillar | Implementation | Cost |
|---|---|---|
| **Naming & Tagging** | Azure CAF naming convention; enforced tag taxonomy (`environment`, `managed_by`, `owner`, `cost_center`) | Free |
| **Governance** | Azure Policy: require tags on RGs, inherit tags to resources, restrict allowed regions, restrict VM SKUs, require secure storage | Free |
| **Security** | Microsoft Defender for Cloud (free tier), Key Vault RBAC, NSG deny-all-inbound, TLS 1.2 enforced, Trusted Launch VMs | Free |
| **Identity** | Key Vault with RBAC authorization, Entra ID OIDC for CI/CD (no secrets) | Free |
| **Networking** | VNets with subnet isolation, NSGs with deny-all-inbound default (multi-region) | Free |
| **Monitoring** | Log Analytics (500 MB/day cap), diagnostic settings on VNet, NSG, Key Vault | Free |
| **Cost Management** | $10/month budget with alerts at 50%, 80%, 100% (forecasted); auto-shutdown VM | Free |
| **State Management** | Remote Terraform state in Azure Storage with blob versioning | ~$0.02/mo |
| **CI/CD** | GitHub Actions with OIDC federated identity, plan on PR, apply on merge | Free |

## Architecture

```
┌──────────────────────────────────────────────────────────────────┐
│  Azure Subscription (Personal)                                   │
│                                                                  │
│  ┌─ Subscription-Level Governance ────────────────────────────┐  │
│  │  Azure Policy: Require tags, allowed locations/VM SKUs     │  │
│  │  Defender for Cloud: Free tier (CSPM)                      │  │
│  │  Budget Alert: $10/month (50% / 80% / 100%)               │  │
│  └────────────────────────────────────────────────────────────┘  │
│                                                                  │
│  ┌─ Entra ID ────────────────────────────────────────────────┐  │
│  │  App Registration: sp-personal-github-actions-dev          │  │
│  │  Federated Credentials: PR, main branch, production env   │  │
│  │  Roles: Contributor, User Access Admin, Blob Data,        │  │
│  │         Key Vault Secrets Officer                          │  │
│  └────────────────────────────────────────────────────────────┘  │
│                                                                  │
│  ┌─ rg-personal-dev-eastus2 ─────────────────────────────────┐  │
│  │                                                            │  │
│  │  ┌─ vnet-personal-dev-eastus2 (10.0.0.0/16) ───────────┐  │  │
│  │  │  └─ snet-default-dev-eastus2 (10.0.1.0/24)          │  │  │
│  │  │     NSG: nsg-default-dev-eastus2 (deny all inbound)  │  │  │
│  │  └──────────────────────────────────────────────────────┘  │  │
│  │                                                            │  │
│  │  Key Vault:     kv-personal-dev-eus2 (RBAC, diagnostics)  │  │
│  │  Log Analytics: log-personal-dev-eastus2 (500MB/day cap)  │  │
│  └────────────────────────────────────────────────────────────┘  │
│                                                                  │
│  ┌─ rg-personal-vm-dev-centralus ────────────────────────────┐  │
│  │                                                            │  │
│  │  ┌─ vnet-personal-vm-dev-centralus (10.1.0.0/16) ──────┐  │  │
│  │  │  └─ snet-vm-dev-centralus (10.1.1.0/24)             │  │  │
│  │  │     NSG: nsg-vm-dev-centralus (deny all + allow RDP) │  │  │
│  │  └──────────────────────────────────────────────────────┘  │  │
│  │                                                            │  │
│  │  VM:  vm-personal-dev-centralus (Standard_D2s_v3)         │  │
│  │       Windows 11 24H2 Ent, Trusted Launch, auto-shutdown  │  │
│  │  NIC: nic-vm-personal-dev-centralus                       │  │
│  │  PIP: pip-vm-personal-dev-centralus (Static, Standard)    │  │
│  └────────────────────────────────────────────────────────────┘  │
│                                                                  │
│  ┌─ rg-tfstate-dev-eastus2 (Bootstrap) ──────────────────────┐  │
│  │  Storage: sttfstatedeveus221b6 (LRS, TLS 1.2, versioned) │  │
│  │  Container: tfstate                                        │  │
│  └────────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────┘
```

## Project Structure

```
my-azure-infra/
├── .github/
│   ├── instructions/           # Copilot instructions for Terraform
│   └── workflows/
│       ├── terraform-plan.yml  # PR: fmt → init → validate → plan → comment
│       └── terraform-apply.yml # Merge to main: init → apply (production env)
├── bootstrap/
│   ├── main.tf                 # Storage account for TF remote state
│   ├── variables.tf
│   └── outputs.tf
├── modules/
│   ├── networking/             # VNet, subnet, NSG, diagnostic settings
│   ├── keyvault/               # Key Vault (RBAC auth), role assignment, diagnostics
│   ├── governance/             # 7 Azure Policy assignments
│   ├── defender/               # Defender free tier, security contact
│   ├── compute/                # Windows 11 VM (self-contained: RG, VNet, subnet, NSG)
│   └── github-oidc/            # Entra ID app, federated creds, role assignments
├── main.tf                     # Root module — resource group, Log Analytics, modules, budget
├── variables.tf                # Input variables with defaults
├── outputs.tf                  # Root outputs
├── providers.tf                # Provider config (azurerm ~> 4.0, azuread ~> 3.0)
├── backend.tf                  # Remote backend (Azure Storage)
├── terraform.tfvars            # Variable values
└── .gitignore
```

## Modules

### networking
VNet, subnet, NSG with deny-all-inbound, diagnostic settings to Log Analytics. Deployed in eastus2.

### keyvault
Key Vault with RBAC authorization enabled (`rbac_authorization_enabled = true`), Key Vault Administrator role for the owner, diagnostic logging (AuditEvent) to Log Analytics.

### governance
7 Azure Policy assignments: require `environment` and `managed_by` tags on resource groups, inherit tags to resources, restrict allowed regions (eastus2, eastus, centralus), restrict VM SKUs to cost-effective sizes, require secure transfer on storage.

### defender
Microsoft Defender for Cloud free tier for VMs, Storage, Key Vaults, and ARM. Security contact email notifications.

### compute
Self-contained Windows 11 development VM in centralus. Creates its own resource group, VNet (10.1.0.0/16), subnet (10.1.1.0/24), and NSG. Features:
- **SKU**: Standard_D2s_v3 (2 vCPU, 8 GB RAM)
- **OS**: Windows 11 24H2 Enterprise, Trusted Launch (secure boot + vTPM)
- **Storage**: 128 GB StandardSSD
- **Security**: NSG deny-all-inbound + allow RDP from specific IP only
- **Cost control**: Auto-shutdown at 7 PM CT daily
- **Credentials**: Admin password stored in Key Vault (eastus2)

### github-oidc
Entra ID app registration with 3 federated identity credentials (PR, main branch, production environment). Service principal with Contributor, User Access Administrator, Storage Blob Data Contributor, and Key Vault Secrets Officer roles at subscription scope.

## CI/CD Pipeline

Automated via **GitHub Actions** with **OIDC** (OpenID Connect) — no secrets stored, only federated identity credentials.

### Workflow

1. **Create a feature branch** and make changes
2. **Open a Pull Request** → triggers `Terraform Plan` workflow
   - Runs format check, init, validate, plan
   - Posts plan output as a PR comment
3. **Merge to main** → triggers `Terraform Apply` workflow
   - Runs init, apply with `-auto-approve`
   - Uses the `production` GitHub environment

### GitHub Secrets Required

| Secret | Description |
|---|---|
| `AZURE_CLIENT_ID` | Entra ID application (client) ID |
| `AZURE_TENANT_ID` | Entra ID tenant ID |
| `AZURE_SUBSCRIPTION_ID` | Azure subscription ID |

These values are output by `terraform output` after initial deployment.

### OIDC Federated Credentials

| Subject | Purpose |
|---|---|
| `repo:<org>/<repo>:pull_request` | Plan on PRs |
| `repo:<org>/<repo>:ref:refs/heads/main` | Apply from main branch |
| `repo:<org>/<repo>:environment:production` | Apply with `production` environment |

## Naming Convention

Follows [Azure CAF naming convention](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/resource-naming):

| Resource           | Pattern                           | Example                      |
| ------------------ | --------------------------------- | ---------------------------- |
| Resource Group     | `rg-<workload>-<env>-<region>`    | `rg-personal-dev-eastus2`   |
| Resource Group (VM)| `rg-<workload>-vm-<env>-<region>` | `rg-personal-vm-dev-centralus` |
| Virtual Network    | `vnet-<workload>-<env>-<region>`  | `vnet-personal-dev-eastus2` |
| Subnet             | `snet-<purpose>-<env>-<region>`   | `snet-default-dev-eastus2`  |
| NSG                | `nsg-<purpose>-<env>-<region>`    | `nsg-default-dev-eastus2`   |
| Virtual Machine    | `vm-<workload>-<env>-<region>`    | `vm-personal-dev-centralus` |
| Public IP          | `pip-<parent>`                    | `pip-vm-personal-dev-centralus` |
| NIC                | `nic-<parent>`                    | `nic-vm-personal-dev-centralus` |
| Storage Account    | `st<workload><env><region_abbr><suffix>`  | `sttfstatedeveus221b6` |
| Key Vault          | `kv-<workload>-<env>-<region_abbr>` | `kv-personal-dev-eus2`    |
| Log Analytics      | `log-<workload>-<env>-<region>`   | `log-personal-dev-eastus2`  |

## Prerequisites

- [Terraform](https://www.terraform.io/downloads) >= 1.9.0
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) >= 2.60
- An Azure subscription

## Getting Started

### 1. Authenticate

```bash
az login
az account set --subscription "<your-subscription-id>"
```

### 2. Bootstrap Terraform State Storage

The bootstrap creates a storage account for remote Terraform state:

```bash
cd bootstrap
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

### 3. Deploy Infrastructure

```bash
cd ..
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

### 4. Configure GitHub Secrets

After initial deployment, set the GitHub Actions secrets from Terraform outputs:

```bash
terraform output github_actions_client_id
terraform output github_actions_tenant_id
terraform output github_actions_subscription_id
```

Set these as repository secrets (`AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID`) in **Settings → Secrets and variables → Actions**.

### 5. Create GitHub Environment

Create a `production` environment in **Settings → Environments** for the apply workflow.

### 6. Connect to the Dev VM

Retrieve the admin password from Key Vault and RDP to the VM:

```bash
# Get the VM public IP
terraform output vm_public_ip

# Get the admin password from Key Vault
az keyvault secret show --vault-name kv-personal-dev-eus2 \
  --name vm-personal-dev-centralus-admin-password --query value -o tsv
```

Connect via RDP to the public IP with username `azureadmin`.

## Cost Estimate

| Resource                | Monthly Cost |
| ----------------------- | ------------ |
| Resource Groups (x2)    | Free         |
| Virtual Networks (x2)   | Free         |
| Subnets + NSGs (x2)     | Free         |
| Key Vault (Standard)    | ~$0.03/key   |
| Log Analytics (500MB)   | Free         |
| Diagnostic Settings     | Free         |
| Azure Policy            | Free         |
| Defender (Free tier)    | Free         |
| Storage (TF state)      | ~$0.02       |
| Budget Alerts           | Free         |
| Entra ID App + SP       | Free         |
| GitHub Actions (public) | Free         |
| **VM: Standard_D2s_v3** | **~$96** (auto-shutdown reduces actual cost) |
| Public IP (Standard)    | ~$3.65       |
| OS Disk (128GB SSD)     | ~$9.60       |
| **Total (VM running 24/7)** | **~$109/mo** |
| **Total (VM ~8hr/day)**     | **~$45/mo**  |
| **Total**               | **< $1/mo**  |

## Variables

| Name                    | Description                              | Default                    |
| ----------------------- | ---------------------------------------- | -------------------------- |
| `project_name`          | Project/workload name                    | `personal`                 |
| `environment`           | Environment (dev/staging/prod)           | `dev`                      |
| `location`              | Azure region                             | `eastus2`                  |
| `owner_email`           | Owner email (tags, security alerts)      | *(required)*               |
| `budget_amount`         | Monthly budget in USD                    | `10`                       |
| `budget_contact_emails` | Emails for budget alerts                 | *(required)*               |
| `address_space`         | VNet address space                       | `10.0.0.0/16`              |
| `subnet_prefix`         | Subnet address prefix                    | `10.0.1.0/24`              |
| `allowed_locations`     | Allowed Azure regions (policy)           | `["eastus2", "eastus"]`    |
| `allowed_vm_skus`       | Allowed VM sizes (policy cost guardrail) | B-series + small D-series  |
| `github_org`            | GitHub org/username for OIDC trust       | `mbouges`                  |
| `github_repo`           | GitHub repo name for OIDC trust          | `my-azure-infra`           |
| `owner_object_id`       | Entra ID object ID of the app owner      | *(required)*               |

## Outputs

| Name                             | Description                          |
| -------------------------------- | ------------------------------------ |
| `resource_group_name`            | Name of the resource group           |
| `resource_group_id`              | ID of the resource group             |
| `vnet_name`                      | Name of the virtual network          |
| `vnet_id`                        | ID of the virtual network            |
| `default_subnet_id`              | ID of the default subnet             |
| `key_vault_name`                 | Name of the Key Vault                |
| `key_vault_uri`                  | URI of the Key Vault                 |
| `log_analytics_workspace_id`     | ID of the Log Analytics workspace    |
| `log_analytics_workspace_name`   | Name of the Log Analytics workspace  |
| `github_actions_client_id`       | AZURE_CLIENT_ID for GitHub Actions   |
| `github_actions_tenant_id`       | AZURE_TENANT_ID for GitHub Actions   |
| `github_actions_subscription_id` | AZURE_SUBSCRIPTION_ID for GitHub Actions |
