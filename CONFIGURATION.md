# Configuration Reference

Complete documentation of the deployed infrastructure, variables, and resource inventory for the Personal Azure Environment.

**Last Updated:** March 25, 2026  
**Deployment Status:** ✅ All resources deployed and synchronized

---

## Table of Contents

1. [Deployed Resources](#deployed-resources)
2. [Variables & Configuration](#variables--configuration)
3. [Networking Topology](#networking-topology)
4. [Security Configuration](#security-configuration)
5. [Governance & Policies](#governance--policies)
6. [Cost Optimization](#cost-optimization)
7. [State Management](#state-management)
8. [GitHub Actions CI/CD](#github-actions-cicd)

---

## Deployed Resources

### Resource Groups

| Name | Location | Purpose | Tags |
|---|---|---|---|
| `rg-personal-dev-eastus2` | eastus2 | Primary infrastructure hub (networking, Key Vault, Log Analytics) | environment=dev, managed_by=terraform, owner=matt.bouges@gmail.com, project=personal, cost_center=personal |
| `rg-personal-vm-dev-centralus` | centralus | Windows 11 VM (self-contained, different region for SKU availability) | environment=dev, managed_by=terraform, owner=matt.bouges@gmail.com, project=personal, cost_center=personal |
| `rg-tfstate-dev-eastus2` | eastus2 | Terraform remote state storage (bootstrap) | — |

### Networking Resources

#### Primary VNet (eastus2)
| Resource | Name | Config |
|---|---|---|
| Virtual Network | `vnet-personal-dev-eastus2` | Address space: 10.0.0.0/16 |
| Subnet | `snet-default-dev-eastus2` | Address prefix: 10.0.1.0/24, no outbound internet access |
| NSG | `nsg-default-dev-eastus2` | Default deny all inbound, diagnostic logging enabled |

#### VM VNet (centralus)
| Resource | Name | Config |
|---|---|---|
| Virtual Network | `vnet-personal-vm-dev-centralus` | Address space: 10.1.0.0/16 |
| Subnet | `snet-vm-dev-centralus` | Address prefix: 10.1.1.0/24 |
| NSG | `nsg-vm-dev-centralus` | Allow Bastion RDP (168.63.129.16/32 on port 3389), diagnostic logging enabled |
| Bastion Host | `bas-personal-vm-dev-centralus` | SKU: Developer (free), browser-based RDP via Azure portal |
| NIC | `nic-vm-personal-dev-centralus` | Private IP only, no public IP |

### Compute

| Resource | Name | Config |
|---|---|---|
| Virtual Machine | `vm-personal-dev-centralus` | OS Disk: 128 GB StandardSSD, Trusted Launch enabled |
| OS | Windows 11 24H2 Enterprise | Latest image, secure kernel launch, vTPM enabled |
| SKU | Standard_D2s_v3 | 2 vCPU, 8 GB RAM (~$0.10/hour, ~$73/month) |
| Admin Username | `azureadmin` | Fixed user |
| Admin Password | Stored in Key Vault | Secret: `vm-personal-dev-centralus-admin-password` |
| Auto-shutdown | 7 PM CT daily | Timezone: Central Standard Time |

### Security & Key Management

| Resource | Name | Config |
|---|---|---|
| Key Vault | `kv-personal-dev-eus2` | SKU: Standard, RBAC auth enabled, purge protection disabled, soft delete: 7 days |
| Network Rules | Allow (default) | Bypass: AzureServices |
| Admin Role | Key Vault Administrator | Principal: matt.bouges@gmail.com (owner) |
| Secrets | VM admin password | Name: `vm-personal-dev-centralus-admin-password` |
| Diagnostics | AuditEvent logging | Target: Log Analytics workspace |

### Monitoring & Logging

| Resource | Name | Config |
|---|---|---|
| Log Analytics | `log-personal-dev-eastus2` | SKU: PerGB2018, retention: 30 days, daily cap: 0.5 GB (free tier) |
| Diagnostic Settings | VNet | Category: VMProtectionAlerts |
| Diagnostic Settings | NSG (primary) | Categories: NetworkSecurityGroupEvent, NetworkSecurityGroupRuleCounter |
| Diagnostic Settings | NSG (VM) | Categories: NetworkSecurityGroupEvent, NetworkSecurityGroupRuleCounter |
| Diagnostic Settings | Key Vault | Category: AuditEvent |

---

## Variables & Configuration

### Environment Configuration

Configured in [terraform.tfvars](terraform.tfvars):

```hcl
# Project Identity
project_name = "personal"
environment  = "dev"
location     = "eastus2"

# Owner & Billing
owner_email           = "matt.bouges@gmail.com"
owner_object_id       = "b53807db-aa6a-4e20-a1f6-7e0e93236c08"
budget_contact_emails = ["matt.bouges@gmail.com"]

# Networking (Primary eastus2)
address_space = "10.0.0.0/16"
subnet_prefix = "10.0.1.0/24"

# Budget
budget_amount = 10  # USD per month

# Governance
allowed_locations = ["eastus2", "eastus", "centralus"]
allowed_vm_skus   = ["Standard_B1s", "Standard_B2s", "Standard_D2s_v3"]

# GitHub CI/CD
github_org      = "mbouges"                          # Updated: was ZMB0002_conagra
github_repo     = "my-azure-infra"
owner_object_id = "b53807db-aa6a-4e20-a1f6-7e0e93236c08"

# VM Configuration (centralus)
vm_size                = "Standard_D2s_v3"
vm_location            = "centralus"
vm_address_space       = "10.1.0.0/16"
vm_subnet_prefix       = "10.1.1.0/24"
auto_shutdown_time     = "1900"              # 7 PM
auto_shutdown_timezone = "Central Standard Time"
```

### Sensitive Variables

Stored securely in Key Vault:

| Variable | Value | Key Vault Secret |
|---|---|---|
| VM Admin Password | Auto-generated (24 chars, special) | `vm-personal-dev-centralus-admin-password` |

### Default Variables (from [variables.tf](variables.tf))

| Variable | Type | Default | Description |
|---|---|---|---|
| `os_disk_type` | string | `StandardSSD_LRS` | VM OS disk storage type |
| `os_disk_size_gb` | number | `128` | VM OS disk size |
| `admin_username` | string | `azureadmin` | VM admin user |

---

## Networking Topology

### IP Address Plan

```
Subscription: cb97925a-92db-40f8-b51c-fb7b2696545c
├── Primary Hub (eastus2)
│   └── rg-personal-dev-eastus2
│       └── vnet-personal-dev-eastus2: 10.0.0.0/16
│           └── snet-default-dev-eastus2: 10.0.1.0/24
│               • Usable IPs: 10.0.1.4 - 10.0.1.254
│               • No internet outbound by default
│               • NSG: Deny all inbound
│
└── Compute Hub (centralus) — Isolated for VM
    └── rg-personal-vm-dev-centralus
        └── vnet-personal-vm-dev-centralus: 10.1.0.0/16
            └── snet-vm-dev-centralus: 10.1.1.0/24
                • Usable IPs: 10.1.1.4 - 10.1.1.254
                • VM NIC: 10.1.1.4 (Dynamic, private only)
                • Bastion: 10.1.1.5 (Dynamic)
                • NSG: Allow Bastion RDP only
```

### Network Security Posture

| VNet | NSG | Inbound Rules | Outbound Rules |
|---|---|---|---|
| vnet-personal-dev-eastus2 | nsg-default-dev-eastus2 | ❌ Deny all (priority 4096) | ✅ Allow all |
| vnet-personal-vm-dev-centralus | nsg-vm-dev-centralus | ✅ Bastion RDP (168.63.129.16/32:3389) | ✅ Allow all |

**Access Pattern:**
1. User authenticates to Azure portal
2. Portal launches Bastion browser session
3. Bastion connects to VM on private IP (10.1.1.4) via RDP
4. All traffic encrypted in transit
5. No public IP exposed

---

## Security Configuration

### Key Vault Security

| Setting | Value | Rationale |
|---|---|---|
| SKU | Standard | Cost-optimized for personal use |
| RBAC Authorization | ✅ Enabled | All access controlled via Azure RBAC, no access policies |
| Network Rules | Default: Allow | Open for personal environment, bypass AzureServices |
| Purge Protection | ❌ Disabled | Allow cleanup in personal environment |
| Soft Delete | 7 days | Minimum retention to minimize cost |
| TLS Version | 1.2+ | Enforced |
| Diagnostics | AuditEvent logging | Tracks all secret access/operations |

**Roles Assigned:**
- `Key Vault Administrator`: matt.bouges@gmail.com (full access)
- `Key Vault Secrets Officer`: sp-personal-github-actions-dev (CI/CD read/manage)

### VM Security

| Feature | Status | Purpose |
|---|---|---|
| **Trusted Launch** | ✅ Enabled | Secure boot + vTPM for Windows 11 |
| **Secure Boot** | ✅ Enabled | Prevents unauthorized code at OS startup |
| **vTPM** | ✅ Enabled | Virtual TPM for attestation |
| **Public IP** | ❌ None | No internet exposure |
| **Admin Password** | 🔐 Vault-stored | 24-char, special chars, auto-generated |
| **Access Method** | Bastion only | Browser-based, no SSH/RDP ports exposed |
| **NSG Rules** | Bastion only | Allow only 168.63.129.16 on port 3389 |

### Defender for Cloud

| Resource Type | Tier | Status |
|---|---|---|
| Virtual Machines | Free | Recommendations & Secure Score |
| Storage Accounts | Free | Vulnerability scanning, recommendations |
| Key Vaults | Free | Recommendations |
| Arm (Resource Manager) | Free | Recommendations |
| **Security Contact** | — | matt.bouges@gmail.com (alerts enabled) |

---

## Governance & Policies

### Azure Policy Assignments (Subscription-Level)

All built-in policies, no cost.

#### Tag Enforcement

| Policy | ID | Scope | Action | Status |
|---|---|---|---|---|
| **Require 'environment' tag on RGs** | 96670d01-0a4d-4649-9c89-2d3abc0a5025 | Subscription | Audit | ✅ Deployed |
| **Require 'managed_by' tag on RGs** | 96670d01-0a4d-4649-9c89-2d3abc0a5025 | Subscription | Audit | ✅ Deployed |
| **Inherit 'environment' tag** | cd3aa116-8754-49c9-a813-ad46512ece54 | Subscription | Modify (Managed ID) | ✅ Deployed |
| **Inherit 'managed_by' tag** | cd3aa116-8754-49c9-a813-ad46512ece54 | Subscription | Modify (Managed ID) | ✅ Deployed |

#### Resource Constraints

| Policy | ID | Scope | Config | Status |
|---|---|---|---|---|
| **Restrict to allowed locations** | e56962a6-4747-49cd-b67b-bf8b01975c4c | Subscription | Allowed: eastus2, eastus, centralus | ✅ Deployed |
| **Restrict VM SKUs** | cccc23c7-8427-4f53-ad12-b6a63eb452b3 | Subscription | Allowed: B1s, B2s, D2s_v3 | ✅ Deployed |
| **Require secure transfer (Storage)** | 404c3081-a854-4457-ae30-26a93ef643f9 | Subscription | HTTPS only | ✅ Deployed |

**Enforcement Mode:** All auditing (no denials). Alerts via Defender for Cloud.

---

## Cost Optimization

### Monthly Cost Estimate

| Resource | Estimate | Notes |
|---|---|---|
| Standard_D2s_v3 VM | $73.00 | 2 vCPU, 8 GB RAM; ~730 hours/month (auto-shutdown 7 PM CT saves ~$25/month) |
| Key Vault Operations | <$1.00 | <10 operations/day |
| Log Analytics | <$1.00 | 500 MB/day cap (free tier) |
| Bastion (Developer) | $0.00 | Free SKU |
| Storage (tfstate) | $0.02 | ~50 MB versioned blob storage |
| Virtual Network | $0.00 | No charge for VNets/subnets/NSGs |
| Defender for Cloud | $0.00 | Free tier only |
| Policies | $0.00 | Built-in, no cost |
| **Total** | **~$74/month** | Average; budget cap: $10 as safety guardrail |

### Cost Controls Implemented

| Control | Mechanism | Savings |
|---|---|---|
| **Auto-shutdown VM** | Daily 7 PM CT | ~$25/month (34% off-hours savings) |
| **Compute SKU** | Standard_D2s_v3 (not Premium) | + Standard disks (not Premium) = ~$73/mo vs. ~$200+/mo for Premium |
| **Region Selection** | eastus2 (cheaper than westus) | ~8-12% vs. westus regional prices |
| **Free Services** | Defender, Policies, VNet, NSG, Bastion Developer | ~$50+/month in foregone costs |
| **Log Analytics Cap** | 0.5 GB/day | Prevents runaway ingestion costs |
| **Soft Delete** | 7 days (minimum) | Reduces Key Vault retention costs |
| **Purge Protection** | Disabled | Eliminates long-term retention fees |

### Budget Alert Configuration

| Threshold | Operator | Alert Type | Recipients |
|---|---|---|---|
| 50% | Greater Than or Equal | Actual | matt.bouges@gmail.com |
| 80% | Greater Than or Equal | Actual | matt.bouges@gmail.com |
| 100% | Greater Than or Equal | **Forecasted** | matt.bouges@gmail.com |

**Alert Behavior:**
- Alerts fire when spending reaches 50%, 80%, or when forecasted to exceed budget
- Provides 3 escalation points to catch overspending
- Forecasted alert gives advance notice of overage

---

## State Management

### Terraform Remote State

Location: Azure Storage (`rg-tfstate-dev-eastus2`)

| Setting | Value |
|---|---|
| Storage Account | `sttfstatedeveus221b6` |
| Container | `tfstate` |
| Blob | `terraform.tfstate` |
| Replication | LRS (Locally Redundant Storage) |
| Versioning | ✅ Enabled (state history preserved) |
| TLS | 1.2+ enforced |
| Access Tier | Hot |
| Soft Delete | 7 days |

**Backend Configuration** ([backend.tf](backend.tf)):
```hcl
backend "azurerm" {
  storage_account_name  = "sttfstatedeveus221b6"
  container_name        = "tfstate"
  key                   = "terraform.tfstate"
  use_msi               = true  # Use managed identity for GitHub Actions
  skip_provider_registration = true
}
```

**Access Controls:**
- GitHub Actions uses OIDC federated identity (no secrets)
- Only the CI/CD service principal has write access
- Manual Azure CLI access via `az login`

---

## GitHub Actions CI/CD

### OIDC Configuration

Entra ID Application:
- **Display Name**: `sp-personal-github-actions-dev`
- **Client ID**: `666167e0-4416-4149-8646-d71915acf9a7`
- **Tenant ID**: `4d98b607-3967-4e84-aea2-4cea85d636d2`
- **Subscription ID**: `cb97925a-92db-40f8-b51c-fb7b2696545c`

### Federated Identity Credentials

All credentials configured for org `mbouges` (updated March 25, 2026):

| Credential | Subject | Purpose |
|---|---|---|
| `github-pr` | `repo:mbouges/my-azure-infra:pull_request` | Plan on PRs |
| `github-main` | `repo:mbouges/my-azure-infra:ref:refs/heads/main` | Apply from main |
| `github-environment-production` | `repo:mbouges/my-azure-infra:environment:production` | Apply with prod env |

### Role Assignments (Service Principal)

Scope: Subscription (`/subscriptions/cb97925a-92db-40f8-b51c-fb7b2696545c`)

| Role | Purpose |
|---|---|
| **Contributor** | Create/manage/delete resources |
| **User Access Administrator** | Manage RBAC (Key Vault, policy identities) |
| **Storage Blob Data Contributor** | Read/write Terraform state |
| **Key Vault Secrets Officer** | Manage VM admin password secret |

### Workflows

#### terraform-plan.yml (Triggered on Pull Request)
```yaml
on: [pull_request]
jobs:
  plan:
    runs-on: ubuntu-latest
    permissions:
      pull-requests: write
    steps:
      - uses: actions/checkout@v4
      - uses: hashicorp/setup-terraform@v3
      - run: terraform fmt -check
      - run: terraform init
      - run: terraform validate
      - run: terraform plan -out=tfplan
      - uses: actions/github-script@v7
        with:
          script: |
            # Comment plan on PR
```

#### terraform-apply.yml (Triggered on Merge to main)
```yaml
on: 
  push:
    branches: [main]
jobs:
  apply:
    runs-on: ubuntu-latest
    environment: production
    steps:
      - uses: actions/checkout@v4
      - uses: hashicorp/setup-terraform@v3
      - run: terraform init
      - run: terraform apply -auto-approve tfplan
```

### Secrets to Configure in GitHub

Add these as repository secrets under **Settings > Secrets and variables > Actions**:

```
AZURE_CLIENT_ID       = 666167e0-4416-4149-8646-d71915acf9a7
AZURE_TENANT_ID       = 4d98b607-3967-4e84-aea2-4cea85d636d2
AZURE_SUBSCRIPTION_ID = cb97925a-92db-40f8-b51c-fb7b2696545c
```

---

## Disaster Recovery & Backup

### State Backup

Terraform state is versioned in Azure Storage:
- Enable recovery from accidental deletions
- Point-in-time recovery available within 7 days
- Revert to previous state by restoring blob version

### Key Vault Soft Delete

7-day soft delete retention allows recovery of accidentally deleted secrets/keys:
```bash
az keyvault secret recover --vault-name kv-personal-dev-eus2 --name vm-personal-dev-centralus-admin-password
```

### VM Snapshot Strategy

No automated backups configured (cost optimization). For production workloads, implement:
```bash
# Manual snapshot before major changes
az snapshot create --resource-group rg-personal-vm-dev-centralus \
  --source vm-personal-dev-centralus \
  --name snapshot-vm-$(date +%Y%m%d)
```

---

## Compliance & Audit Trail

### Logging Configuration

| Log Source | Target | Retention | Categories |
|---|---|---|---|
| Virtual Network | Log Analytics | 30 days | VMProtectionAlerts |
| Network Security Group | Log Analytics | 30 days | NetworkSecurityGroupEvent, NetworkSecurityGroupRuleCounter |
| Key Vault | Log Analytics | 30 days | AuditEvent (all operations) |

### Audit & Compliance

- **Azure Policy**: 7 assignments monitoring resource compliance
- **Defender for Cloud**: Free tier CSPM (Cloud Security Posture Management)
- **Tags**: CAF-Lite taxonomy enforced on all resources
- **Access Logs**: Key Vault audit event logging

### Data Subject Rights

All personal data is minimal (email, owner ID). To comply with data requests:
1. Resource tags contain `owner` email
2. Key Vault audit logs retention: 30 days
3. Log Analytics retention: 30 days
4. After 30 days, all logs are purged

---

## Maintenance & Updates

### Terraform Version

- **Current**: v1.9.0 or later
- **Provider Versions**: 
  - azurerm ~> 4.0 (latest stable)
  - azuread ~> 3.0 (latest stable)
  - random ~> 3.0

### Regular Tasks

| Task | Frequency | Owner |
|---|---|---|
| Review budget alerts | Monthly | Auto-email |
| Review Defender for Cloud recommendations | Monthly | Manual review |
| Review Key Vault audit logs | Quarterly | Manual review |
| Update Terraform providers | Quarterly | Manual (via `terraform init`) |
| Review policy complianceStatus | Quarterly | Manual via portal |

### Known Limitations

1. **Purge Protection Disabled**: Allows accidental key vault deletion (acceptable for personal dev env)
2. **Auto-backup Disabled**: No automated VM backups (cost optimization)
3. **No Multi-region DR**: Single-region deployment (acceptable for personal workload)
4. **Soft Delete 7 days**: Minimum retention for Key Vault (cost optimization)

---

## Troubleshooting

### Common Issues

**Issue**: Terraform plan shows changes on every run

**Solutions**:
- Run `terraform refresh` to sync state
- Check for environment variable drift in `.tfvars`
- Verify all variables are defined in `variables.tf`

---

**Issue**: GitHub Actions OIDC authentication fails

**Solutions**:
- Verify Entra ID app registration is active: `az ad app show --id 666167e0-4416-4149-8646-d71915acf9a7`
- Check federated credentials: `az ad app federated-credential list --id 666167e0-4416-4149-8646-d71915acf9a7`
- Verify GitHub org/repo match configured subjects
- Confirm role assignments exist: `az role assignment list --assignee 666167e0-4416-4149-8646-d71915acf9a7`

---

**Issue**: Key Vault access denied

**Solutions**:
- Verify RBAC role assignment: `az role assignment list --scope /subscriptions/.../providers/Microsoft.KeyVault/vaults/kv-personal-dev-eus2 --assignee <principal-id>`
- Check Key Vault network rules: `az keyvault show --name kv-personal-dev-eus2 --query networkAcls`
- Ensure `rbac_authorization_enabled = true` (not access policies)

---

## Related Documentation

- [README.md](README.md) — Overview, architecture, getting started
- [bootstrap/README.md](bootstrap/README.md) — Terraform state setup
- [modules/*/README.md](modules/) — Module-specific documentation
- [.github/workflows/](/.github/workflows/) — CI/CD pipeline definitions

---

**Last Updated**: March 25, 2026 ✅ All resources synchronized  
**Maintained by**: mbouges  
**Support**: [GitHub Issues](https://github.com/mbouges/my-azure-infra/issues)
