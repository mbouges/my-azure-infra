# My Azure Infrastructure

Personal Azure environment provisioned with Terraform, following a **CAF-Lite** (Cloud Adoption Framework — Lite) approach optimized for personal/individual use.

## CAF-Lite Framework

This project implements a lightweight version of the [Azure Cloud Adoption Framework](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/) covering all key pillars with cost-free or near-free services:

| CAF Pillar | Implementation | Cost |
|---|---|---|
| **Naming & Tagging** | Azure CAF naming convention; enforced tag taxonomy (`environment`, `managed_by`, `owner`, `cost_center`) | Free |
| **Governance** | Azure Policy: require tags on RGs, inherit tags to resources, restrict allowed regions, restrict VM SKUs, require secure storage | Free |
| **Security** | Microsoft Defender for Cloud (free tier), Key Vault RBAC, NSG deny-all-inbound, TLS 1.2 enforced | Free |
| **Identity** | Key Vault with RBAC authorization, current principal granted KV Admin | Free |
| **Networking** | VNet with subnet isolation, NSG with deny-all-inbound default | Free |
| **Monitoring** | Log Analytics (500 MB/day cap), diagnostic settings on VNet, NSG, Key Vault | Free |
| **Cost Management** | $10/month budget with alerts at 50%, 80%, 100% (forecasted) | Free |
| **State Management** | Remote Terraform state in Azure Storage with blob versioning | ~$0.02/mo |

## Architecture

```
┌──────────────────────────────────────────────────────────────┐
│  Azure Subscription (Personal)                               │
│                                                              │
│  ┌─ Subscription-Level Governance ────────────────────────┐  │
│  │  Azure Policy: Require tags, allowed locations/VM SKUs │  │
│  │  Defender for Cloud: Free tier (CSPM)                  │  │
│  │  Budget Alert: $10/month (50% / 80% / 100%)            │  │
│  └────────────────────────────────────────────────────────┘  │
│                                                              │
│  ┌─ rg-personal-dev-eastus2 ─────────────────────────────┐  │
│  │                                                        │  │
│  │  ┌─ vnet-personal-dev-eastus2 (10.0.0.0/16) ───────┐  │  │
│  │  │                                                   │  │  │
│  │  │  ┌─ snet-default-dev-eastus2 (10.0.1.0/24) ──┐  │  │  │
│  │  │  │  NSG: nsg-default-dev-eastus2              │  │  │  │
│  │  │  │  Rule: Deny all inbound from Internet      │  │  │  │
│  │  │  └────────────────────────────────────────────┘  │  │  │
│  │  └──────────────────────────────────────────────────┘  │  │
│  │                                                        │  │
│  │  Key Vault:      kv-personal-dev-eus2  (RBAC, diags)  │  │
│  │  Log Analytics:  log-personal-dev-eastus2 (500MB cap)  │  │
│  └────────────────────────────────────────────────────────┘  │
│                                                              │
│  ┌─ rg-tfstate-dev-eastus2 (Bootstrap) ──────────────────┐  │
│  │  Storage: sttfstatedeveus2 (LRS, TLS 1.2, versioned)  │  │
│  │  Container: tfstate                                    │  │
│  └────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────┘
```

## Naming Convention

Follows [Azure CAF naming convention](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/resource-naming):

| Resource           | Pattern                           | Example                      |
| ------------------ | --------------------------------- | ---------------------------- |
| Resource Group     | `rg-<workload>-<env>-<region>`    | `rg-personal-dev-eastus2`   |
| Virtual Network    | `vnet-<workload>-<env>-<region>`  | `vnet-personal-dev-eastus2` |
| Subnet             | `snet-<purpose>-<env>-<region>`   | `snet-default-dev-eastus2`  |
| NSG                | `nsg-<purpose>-<env>-<region>`    | `nsg-default-dev-eastus2`   |
| Storage Account    | `st<workload><env><region_abbr>`  | `sttfstatedeveus2`           |
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

## Cost Estimate

| Resource                | Monthly Cost |
| ----------------------- | ------------ |
| Resource Group          | Free         |
| Virtual Network         | Free         |
| Subnet + NSG            | Free         |
| Key Vault (Standard)    | ~$0.03/key   |
| Log Analytics (500MB)   | Free         |
| Diagnostic Settings     | Free         |
| Azure Policy            | Free         |
| Defender (Free tier)    | Free         |
| Storage (TF state)      | ~$0.02       |
| Budget Alerts           | Free         |
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

## Outputs

| Name                      | Description                    |
| ------------------------- | ------------------------------ |
| `resource_group_name`     | Name of the resource group     |
| `resource_group_id`       | ID of the resource group       |
| `vnet_name`               | Name of the virtual network    |
| `vnet_id`                 | ID of the virtual network      |
| `default_subnet_id`       | ID of the default subnet       |
| `key_vault_name`          | Name of the Key Vault          |
| `key_vault_uri`           | URI of the Key Vault           |
| `log_analytics_workspace_id` | ID of the Log Analytics workspace |
