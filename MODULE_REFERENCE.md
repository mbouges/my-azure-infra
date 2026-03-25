# Module Reference Guide

Detailed documentation of each Terraform module in the Personal Azure Infrastructure project.

---

## Overview

The project is organized into 6 reusable modules, each responsible for a specific domain:

| Module | Purpose | Resources | Location |
|---|---|---|---|
| `networking` | VNets, subnets, NSGs, diagnostic logging | 7 | `./modules/networking/` |
| `keyvault` | Secure secret management with RBAC | 3 | `./modules/keyvault/` |
| `governance` | Azure Policy assignments (CAF-Lite) | 7 | `./modules/governance/` |
| `defender` | Defender for Cloud configuration | 6 | `./modules/defender/` |
| `compute` | Windows 11 VM with Bastion access | 13 | `./modules/compute/` |
| `github-oidc` | Entra ID app + OIDC federated credentials | 9 | `./modules/github-oidc/` |

---

## Module: networking

**Purpose**: Create isolated virtual network infrastructure with security baseline

**Location**: `./modules/networking/`

### Variables

| Variable | Type | Default | Required | Description |
|---|---|---|---|---|
| `project_name` | string | — | ✅ | Project/workload name (e.g., "personal") |
| `environment` | string | — | ✅ | Environment name (e.g., "dev") |
| `location` | string | — | ✅ | Azure region (e.g., "eastus2") |
| `resource_group_name` | string | — | ✅ | Name of existing resource group |
| `address_space` | string | — | ✅ | VNet CIDR (e.g., "10.0.0.0/16") |
| `subnet_prefix` | string | — | ✅ | Subnet CIDR (e.g., "10.0.1.0/24") |
| `log_analytics_workspace_id` | string | — | ✅ | ID of Log Analytics workspace for diagnostics |
| `tags` | map(string) | `{}` | ✅ | Resource tags |

### Outputs

| Output | Type | Description |
|---|---|---|
| `vnet_id` | string | Virtual Network resource ID |
| `vnet_name` | string | Virtual Network name |
| `subnet_id` | string | Subnet resource ID |
| `nsg_id` | string | Network Security Group resource ID |
| `nsg_name` | string | Network Security Group name |

### Resources Created

```
1. azurerm_virtual_network (1)
   └─ vnet-<project>-<env>-<location>
      └─ Default outbound access disabled
      
2. azurerm_subnet (1)
   └─ snet-<purpose>-<env>-<location>
      └─ No network policies enabled
      
3. azurerm_network_security_group (1)
   └─ nsg-<purpose>-<env>-<location>
      └─ Base security posture: deny-all-inbound
      
4. azurerm_network_security_rule (1)
   └─ DenyAllInbound (priority 4096, Internet → *)
   
5. azurerm_subnet_network_security_group_association (1)

6. azurerm_monitor_diagnostic_setting (2)
   ├─ VNet diagnostics (VMProtectionAlerts)
   └─ NSG diagnostics (NetworkSecurityGroupEvent, Rule Counter)
```

### Usage Example

```hcl
module "networking" {
  source = "./modules/networking"

  project_name               = var.project_name
  environment                = var.environment
  location                   = azurerm_resource_group.main.location
  resource_group_name        = azurerm_resource_group.main.name
  address_space              = var.address_space
  subnet_prefix              = var.subnet_prefix
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
  tags                       = local.tags
}
```

### Security Notes

- **Deny-All Baseline**: NSG defaults to deny all inbound traffic (explicit allow required)
- **No Internet Outbound Access**: Disabled by default for eastus2 primary subnet
- **Subnet Isolation**: No network policies (service endpoints, private endpoints) by default
- **Diagnostic Logging**: All VNet and NSG events logged to Log Analytics

### Cost Impact

- VNets, subnets, NSGs: **Free**
- Diagnostic logging: Included in Log Analytics (capped at 0.5 GB/day)

---

## Module: keyvault

**Purpose**: Secure credential storage with RBAC authorization

**Location**: `./modules/keyvault/`

### Variables

| Variable | Type | Default | Required | Description |
|---|---|---|---|---|
| `project_name` | string | — | ✅ | Project/workload name |
| `environment` | string | — | ✅ | Environment name |
| `location` | string | — | ✅ | Azure region |
| `region_abbr` | string | — | ✅ | Region abbreviation (e.g., "eus2") for naming |
| `resource_group_name` | string | — | ✅ | Existing resource group name |
| `log_analytics_workspace_id` | string | — | ✅ | Log Analytics ID for diagnostics |
| `tags` | map(string) | `{}` | ✅ | Resource tags |
| `owner_object_id` | string | — | ✅ | Entra ID object ID of Key Vault admin |
| `tenant_id` | string | — | ✅ | Entra ID tenant ID |

### Outputs

| Output | Type | Description |
|---|---|---|
| `key_vault_id` | string | Key Vault resource ID |
| `key_vault_name` | string | Key Vault name |
| `key_vault_uri` | string | Key Vault URI (for CLI access) |

### Resources Created

```
1. azurerm_key_vault (1)
   └─ kv-<project>-<env>-<abbr> (max 24 chars)
      ├─ SKU: Standard
      ├─ RBAC Authorization: Enabled
      ├─ Purge Protection: Disabled
      ├─ Soft Delete: 7 days
      └─ Network ACLs: Allow (bypass AzureServices)
      
2. azurerm_role_assignment (1)
   └─ Key Vault Administrator → owner_object_id
   
3. azurerm_monitor_diagnostic_setting (1)
   └─ AuditEvent logging → Log Analytics
```

### Usage Example

```hcl
module "keyvault" {
  source = "./modules/keyvault"

  project_name               = var.project_name
  environment                = var.environment
  location                   = azurerm_resource_group.main.location
  region_abbr                = local.abbr
  resource_group_name        = azurerm_resource_group.main.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
  tags                       = local.tags
  owner_object_id            = var.owner_object_id
  tenant_id                  = data.azurerm_subscription.current.tenant_id
}
```

### Security Notes

- **RBAC-Only Authorization**: No access policies; all access via Azure RBAC
- **Soft Delete 7 Days**: Allows recovery of accidentally deleted secrets
- **Purge Protection Disabled**: Acceptable for personal dev environment; allows complete cleanup
- **Network ACLs Permissive**: Open for personal environment; restrict for production
- **Audit Logging**: All operations logged (access, create, delete, etc.)

### Best Practices

1. Use `Key Vault Administrator` role for infrastructure admins only
2. Delegate `Key Vault Secrets Officer` to application identities (e.g., GitHub Actions)
3. Enable purge protection for production key vaults
4. Regularly review audit logs for unauthorized access attempts
5. Use Key Vault's `Backup` feature before major changes

### Cost Impact

- **Standard tier**: ~$0.03/day (~$0.90/month)
- **Operations**: ~$0.06 per 10,000 operations (minimal for personal use)
- **Diagnostics**: Included in Log Analytics

---

## Module: governance

**Purpose**: Implement CAF-Lite governance via Azure Policy assignments

**Location**: `./modules/governance/`

### Variables

| Variable | Type | Default | Required | Description |
|---|---|---|---|---|
| `location` | string | — | ✅ | Primary Azure region (for managed identities) |
| `allowed_locations` | list(string) | — | ✅ | List of allowed regions (e.g., ["eastus2", "eastus"]) |
| `allowed_vm_skus` | list(string) | — | ✅ | List of allowed VM sizes (e.g., ["Standard_B1s", "Standard_D2s_v3"]) |

### Outputs

| Output | Type | Description |
|---|---|---|
| `policy_assignment_ids` | map(string) | Map of policy assignment names to IDs |

### Resources Created

```
1. azurerm_subscription_policy_assignment (7)
   ├─ require-environment-tag-rg
   ├─ require-managed-by-tag-rg
   ├─ inherit-environment-tag (with managed identity)
   ├─ inherit-managed-by-tag (with managed identity)
   ├─ allowed-locations
   ├─ allowed-vm-skus
   └─ require-secure-transfer-storage
```

### Policy Definitions

#### 1. Require 'environment' Tag on RGs

- **Policy ID**: `96670d01-0a4d-4649-9c89-2d3abc0a5025`
- **Action**: Audit (non-blocking)
- **Scope**: Resource Groups
- **Effect**: Identifies RGs without 'environment' tag

#### 2. Require 'managed_by' Tag on RGs

- **Policy ID**: `96670d01-0a4d-4649-9c89-2d3abc0a5025`
- **Action**: Audit (non-blocking)
- **Scope**: Resource Groups
- **Effect**: Identifies RGs without 'managed_by' tag

#### 3. Inherit 'environment' Tag

- **Policy ID**: `cd3aa116-8754-49c9-a813-ad46512ece54`
- **Action**: Modify (auto-remediation)
- **Scope**: All resources
- **Effect**: Auto-adds 'environment' tag from parent RG if missing
- **Requires**: Managed Identity

#### 4. Inherit 'managed_by' Tag

- **Policy ID**: `cd3aa116-8754-49c9-a813-ad46512ece54`
- **Action**: Modify (auto-remediation)
- **Scope**: All resources
- **Effect**: Auto-adds 'managed_by' tag from parent RG if missing
- **Requires**: Managed Identity

#### 5. Restrict to Allowed Locations

- **Policy ID**: `e56962a6-4747-49cd-b67b-bf8b01975c4c`
- **Action**: Deny (blocking)
- **Scope**: All resources
- **Allowed Locations**: eastus2, eastus, centralus
- **Effect**: Prevents resource creation outside allowed regions

#### 6. Restrict VM SKUs

- **Policy ID**: `cccc23c7-8427-4f53-ad12-b6a63eb452b3`
- **Action**: Deny (blocking)
- **Scope**: Virtual Machines
- **Allowed SKUs**: B1s, B2s, D2s_v3 (cost-optimized)
- **Effect**: Blocks creation of expensive VM sizes (e.g., Premium, GPU)

#### 7. Require Secure Transfer on Storage

- **Policy ID**: `404c3081-a854-4457-ae30-26a93ef643f9`
- **Action**: Deny (blocking)
- **Scope**: Storage Accounts
- **Requirement**: HTTPS-only (TLS 1.2)
- **Effect**: Prevents unencrypted storage access

### Usage Example

```hcl
module "governance" {
  source = "./modules/governance"

  location          = var.location
  allowed_locations = var.allowed_locations
  allowed_vm_skus   = var.allowed_vm_skus
}
```

### Compliance Notes

- **Audit vs. Deny**: Tagging policies audit (alert); size/location policies deny (block)
- **Exclusions**: Policies can be excluded per resource group if needed (via portal)
- **Remediate Existing Resources**: Non-compliant resources can be bulk-remediated from policy view
- **Regularly Review**: Monitor policy compliance in Azure Portal > Policy > Compliance

### Cost Impact

- **Built-in Policies**: Free (no cost for policy evaluation)
- **Managed Identity**: Free (auto-created for modification policies)

---

## Module: defender

**Purpose**: Enable Microsoft Defender for Cloud at free tier

**Location**: `./modules/defender/`

### Variables

| Variable | Type | Default | Required | Description |
|---|---|---|---|---|
| `security_contact_email` | string | — | ✅ | Email for security alerts |

### Outputs

| Output | Type | Description |
|---|---|---|
| None | — | — |

### Resources Created

```
1. azurerm_security_center_subscription_pricing (4)
   ├─ VirtualMachines: Free
   ├─ StorageAccounts: Free
   ├─ KeyVaults: Free
   └─ Arm: Free
   
2. azurerm_security_center_contact (1)
   └─ Email notifications enabled
```

### Features Enabled (Free Tier)

| Feature | Capability | Cost |
|---|---|---|
| **CSPM** | Cloud Security Posture Management | Free |
| **Recommendations** | Security best practice recommendations | Free |
| **Secure Score** | Security posture scoring | Free |
| **Benchmark** | Azure Security Benchmark compliance | Free |
| **Alerts** | Email notifications to contact | Free |
| **Advanced Threat Protection** | Not included (paid tier) | — |
| **VA Scanning** | Vulnerability assessment for VMs | Paid tier only |

### Usage Example

```hcl
module "defender" {
  source = "./modules/defender"

  security_contact_email = var.owner_email
}
```

### Security Recommendations

1. **Review Recommendations Weekly**: Check Defender for Cloud dashboard for action items
2. **Prioritize High-Severity**: Address critical vulnerabilities first
3. **Secure Score Target**: Aim for 70%+ secure score
4. **Auto-provisioning**: Ensure agents are deployed on VMs for vulnerability scanning
5. **Upgrade to Paid Tier**: For production workloads requiring advanced threat protection

### Cost Impact

- **Free Tier**: No cost
- **Alerts & Recommendations**: No metering, all included
- **Note**: Upgrade to Standard tier ($15/vCPU/month) for advanced features like VM threat detection

---

## Module: compute

**Purpose**: Provision Windows 11 VM with Bastion access, auto-shutdown, and Trusted Launch

**Location**: `./modules/compute/`

### Variables

| Variable | Type | Default | Required | Description |
|---|---|---|---|---|
| `project_name` | string | — | ✅ | Project/workload name |
| `environment` | string | — | ✅ | Environment name |
| `vm_name` | string | — | ✅ | VM name (must be unique) |
| `computer_name` | string | — | ✅ | Windows computer name (max 15 chars) |
| `location` | string | — | ✅ | Azure region |
| `key_vault_id` | string | — | ✅ | Key Vault ID for admin password storage |
| `address_space` | string | — | ✅ | VNet CIDR (e.g., "10.1.0.0/16") |
| `subnet_prefix` | string | — | ✅ | Subnet CIDR (e.g., "10.1.1.0/24") |
| `vm_size` | string | `Standard_D2s_v3` | ⚠️ | VM SKU (must be in allowed list) |
| `os_disk_type` | string | `StandardSSD_LRS` | ⚠️ | OS disk storage type |
| `os_disk_size_gb` | number | `128` | ⚠️ | OS disk size |
| `admin_username` | string | `azureadmin` | ⚠️ | VM admin username |
| `auto_shutdown_time` | string | — | ✅ | Daily shutdown time (24-hr, e.g., "1900") |
| `auto_shutdown_timezone` | string | — | ✅ | Shutdown timezone (e.g., "Central Standard Time") |
| `tags` | map(string) | `{}` | ✅ | Resource tags |

### Outputs

| Output | Type | Description |
|---|---|---|
| `vm_id` | string | Virtual Machine resource ID |
| `vm_name` | string | Virtual Machine name |
| `private_ip` | string | VM private IP address |
| `bastion_id` | string | Bastion host resource ID |
| `admin_password_secret_name` | string | Key Vault secret name for admin password |

### Resources Created

```
1. azurerm_resource_group (1)
   └─ rg-<project>-vm-<env>-<region>
   
2. azurerm_virtual_network (1)
   └─ vnet-<project>-vm-<env>-<region>
   
3. azurerm_subnet (1)
   └─ snet-vm-<env>-<region>
   
4. azurerm_network_security_group (1)
   └─ nsg-vm-<env>-<region>
   
5. azurerm_network_security_rule (1)
   └─ AllowBastionRDP (allow 168.63.129.16 on 3389)
   
6. azurerm_subnet_network_security_group_association (1)

7. azurerm_bastion_host (1)
   └─ bas-<project>-vm-<env>-<region> (Developer SKU)
   
8. azurerm_network_interface (1)
   └─ nic-vm-<name> (private IP only)
   
9. azurerm_windows_virtual_machine (1)
   └─ vm-<name>
      ├─ Windows 11 24H2 Enterprise
      ├─ Trusted Launch: enabled
      ├─ Secure Boot: enabled
      ├─ vTPM: enabled
      └─ Admin password: generated & stored in Key Vault
      
10. azurerm_managed_disk (1)
    └─ osdisk-<name> (128 GB StandardSSD)
    
11. azurerm_dev_test_global_vm_shutdown_schedule (1)
    └─ Daily shutdown at configured time
    
12. random_password (1)
    └─ 24-char admin password
    
13. azurerm_key_vault_secret (1)
    └─ Admin password stored in Key Vault
```

### Usage Example

```hcl
module "compute" {
  source = "./modules/compute"

  project_name               = var.project_name
  environment                = var.environment
  vm_name                    = "vm-${var.project_name}-${var.environment}-${var.vm_location}"
  computer_name              = "dev-ide"
  location                   = var.vm_location
  key_vault_id               = module.keyvault.key_vault_id
  address_space              = var.vm_address_space
  subnet_prefix              = var.vm_subnet_prefix
  vm_size                    = var.vm_size
  auto_shutdown_time         = var.auto_shutdown_time
  auto_shutdown_timezone     = var.auto_shutdown_timezone
  tags                       = local.tags
}
```

### Security Notes

- **Trusted Launch**: Secure kernel launch with TPM attestation
- **Secure Boot**: Prevents unauthorized boot code
- **vTPM**: Virtual TPM for device integrity measurement
- **No Public IP**: Private NIC only; Bastion provides secure access
- **Admin Password**: Auto-generated, 24 chars with special chars; stored in Key Vault
- **Network Isolation**: Self-contained in separate VNet and RG from primary infrastructure

### Access Instructions

1. Log in to Azure Portal
2. Navigate to Virtual Machines > `vm-personal-dev-centralus`
3. Click "Connect" > "Connect via Bastion"
4. Select "Bastion" in dropdown
5. Username: `azureadmin`
6. Password: Retrieve from Key Vault secret `vm-personal-dev-centralus-admin-password`
7. Browser-based RDP session opens

### Cost Optimization

| Feature | Savings |
|---|---|
| Auto-shutdown 7 PM CT | ~$25/month (34% off-hours savings) |
| Standard SSD (not Premium) | ~$5/month |
| StandardSSD storage tier | Included in VM pricing |
| Bastion Developer (not Standard) | Free (vs. $0.05/connection) |
| No public IP | No IP address charges |

### Known Behaviors

- **Admin Password**: Stored in Terraform state (in Key Vault). If lost, reset via Azure portal
- **Shutdown Notification**: 15-minute advance warning before auto-shutdown (disable via portal)
- **Restart**: Manual restart required after auto-shutdown

---

## Module: github-oidc

**Purpose**: Configure OpenID Connect (OIDC) federated identity for GitHub Actions CI/CD

**Location**: `./modules/github-oidc/`

### Variables

| Variable | Type | Default | Required | Description |
|---|---|---|---|---|
| `project_name` | string | — | ✅ | Project/workload name |
| `environment` | string | — | ✅ | Environment name |
| `github_org` | string | — | ✅ | GitHub organization name (e.g., "mbouges") |
| `github_repo` | string | — | ✅ | GitHub repository name (e.g., "my-azure-infra") |
| `owner_object_id` | string | — | ✅ | Entra ID object ID of app owner |

### Outputs

| Output | Type | Description |
|---|---|---|
| `github_actions_client_id` | string | Entra ID application (client) ID |
| `github_actions_tenant_id` | string | Entra ID tenant ID |
| `github_actions_subscription_id` | string | Azure subscription ID |

### Resources Created

```
1. azuread_application (1)
   └─ sp-<project>-github-actions-<env>
      └─ MS Graph permission: Application.ReadWrite.OwnedBy
      
2. azuread_service_principal (1)
   └─ Linked to app registration
   
3. azuread_application_federated_identity_credential (3)
   ├─ github-pr: repo:<org>/<repo>:pull_request
   ├─ github-main: repo:<org>/<repo>:ref:refs/heads/main
   └─ github-environment-production: repo:<org>/<repo>:environment:production
   
4. azurerm_role_assignment (4)
   ├─ Contributor
   ├─ User Access Administrator
   ├─ Storage Blob Data Contributor
   └─ Key Vault Secrets Officer
```

### Usage Example

```hcl
module "github_oidc" {
  source = "./modules/github-oidc"

  project_name    = var.project_name
  environment     = var.environment
  github_org      = var.github_org
  github_repo     = var.github_repo
  owner_object_id = var.owner_object_id
}
```

### Setup Instructions

1. **Deploy Module**: Run `terraform apply` to create Entra ID app and credentials

2. **Get Output Values**:
   ```bash
   terraform output github_actions_client_id
   terraform output github_actions_tenant_id
   terraform output github_actions_subscription_id
   ```

3. **Configure GitHub Repository Secrets**:
   - Go to GitHub Repo > Settings > Secrets and variables > Actions
   - Add secrets:
     - `AZURE_CLIENT_ID` = (app ID from step 2)
     - `AZURE_TENANT_ID` = (tenant ID from step 2)
     - `AZURE_SUBSCRIPTION_ID` = (subscription ID from step 2)

4. **Add GitHub Environments** (optional, for production gates):
   - Go to GitHub Repo > Settings > Environments
   - Create "production" environment
   - Add deployment protection rule: require approval

5. **Test OIDC Authentication**:
   - Open a PR with a dummy commit
   - Check GitHub Actions > terraform-plan workflow
   - Verify "plan" job completes without auth errors

### OIDC vs. Service Principal Secrets

| Aspect | OIDC | Service Principal Secrets |
|---|---|---|
| **Secrets Stored** | ✅ None (federated only) | ❌ Client secret stored in GitHub |
| **Secret Rotation** | ✅ No rotation needed | ❌ Manual rotation required |
| **Scope** | ✅ Limited to repo & branch | ❌ Global to SP |
| **Audit Trail** | ✅ OIDC token in logs | ❌ All commits can use secret |
| **Security** | ✅ Highest (no secrets) | ⚠️ High (if secret is leaked) |

**OIDC is recommended security best practice.**

### Trust Relationships

The three federated credentials create trust for specific GitHub Actions scenarios:

#### 1. Pull Request Runs
```
Condition: When PR opened/updated against any branch
Subject: repo:mbouges/my-azure-infra:pull_request
Effect: Allows terraform plan (read-only checks)
```

#### 2. Main Branch Pushes
```
Condition: When code merged to main branch
Subject: repo:mbouges/my-azure-infra:ref:refs/heads/main
Effect: Allows terraform apply (production-like, without environment gate)
```

#### 3. Production Environment
```
Condition: When deploying from production GitHub environment
Subject: repo:mbouges/my-azure-infra:environment:production
Effect: Allows terraform apply with manual approval gate
```

### Role Assignments Deep Dive

| Role | Why Needed | Risk Level |
|---|---|---|
| **Contributor** | Create/update/delete all resources | High (full write access) |
| **User Access Administrator** | Manage RBAC (needed for Key Vault admins, policies) | Critical (can grant permissions) |
| **Storage Blob Data Contributor** | Read/write Terraform state | Medium (state contains sensitive info) |
| **Key Vault Secrets Officer** | Create/update secrets (VM admin password) | Medium (manage VM credentials) |

⚠️ **Principle of Least Privilege Note**: These 4 roles are necessary for full IaC management. For tighter control, split into separate SPs (plan-only vs. apply-only).

### Security Best Practices

1. **Scope OIDC Credentials**: Only trust specific repos/branches (configured in federated credentials)
2. **Use Environments**: GitHub environments provide manual gates for `main` branch deployments
3. **Audit Access**: Enable "Settings > Log activity" in GitHub repo
4. **Monitor Azure**: Review Entra ID app permissions in Azure Portal regularly
5. **Disable Unused Credentials**: Remove federated credentials for old branches

### Cost Impact

- **Entra ID App Registration**: Free
- **Federated Credentials**: Free
- **Role Assignments**: Free (but enable resource creation, thus indirect cost)

---

## Module Dependency Graph

```
Root Module (main.tf)
│
├─ networking ────────────────────────────────────────┐
│  └─ Provides: vnet_id, subnet_id, nsg_id           │
│                                                    │
├─ keyvault ───────────────────────────────────────────┤
│  └─ Provides: key_vault_id                         │
│                                                    │
├─ compute (depends on keyvault) ──────────────────────┤
│  ├─ Input: key_vault_id from keyvault              │
│  └─ Stores: admin password in Key Vault            │
│                                                    │
├─ governance ──────────────────────────────────────────┤
│  ├─ Independent (subscription-level)               │
│  └─ Affects: All resources enforce tags/locations  │
│                                                    │
├─ defender ────────────────────────────────────────────┤
│  ├─ Independent (subscription-level)               │
│  └─ Monitors: All resources (VMs, Storage, KV)    │
│                                                    │
└─ github-oidc ────────────────────────────────────────┘
   ├─ Independent (Entra ID-only)
   └─ Enables: CI/CD access to manage resources
```

---

## Module Best Practices

### General

1. **Variables**: Always use variables; avoid hardcoding values
2. **Outputs**: Export all important resource attributes (IDs, names, IPs)
3. **Comments**: Document complex logic and assumptions
4. **Naming**: Follow Azure CAF conventions consistently
5. **Tags**: Pass tags from root module to all resources

### Testing Modules

```bash
# Format check
terraform fmt -check -recursive ./modules

# Validate syntax
terraform validate -compact-warnings

# Dry run (plan)
terraform plan -out=tfplan

# Apply safely
terraform apply tfplan
```

### Adding New Modules

1. Create directory: `mkdir -p ./modules/<name>`
2. Create files: `main.tf`, `variables.tf`, `outputs.tf`, `README.md`
3. Add to root `main.tf`:
   ```hcl
   module "<name>" {
     source = "./modules/<name>"
     
     # Pass all required variables ...
   }
   ```
4. Export outputs if needed
5. Reference in other modules via `module.<name>.outputs`

---

## Cross-Module References

| From | To | Reference | Used For |
|---|---|---|---|
| root (main.tf) | networking | `module.networking.vnet_id` | NSG association |
| root (main.tf) | keyvault | `module.keyvault.key_vault_id` | Store VM password |
| root (main.tf) | compute | `module.keyvault.key_vault_id` | Admin credential |
| governance | — | data.azurerm_subscription | Policy scope |
| defender | — | data.azurerm_subscription | Pricing scope |
| github-oidc | — | data.azurerm_subscription | Role assignment scope |

---

## Troubleshooting by Module

### Networking Issues

**Problem**: Subnet creation fails with invalid CIDR

**Solution**: Ensure `subnet_prefix` is within `address_space`:
- ❌ address_space = "10.0.0.0/16" + subnet_prefix = "10.1.0.0/24" (outside)
- ✅ address_space = "10.0.0.0/16" + subnet_prefix = "10.0.1.0/24" (inside)

### Key Vault Issues

**Problem**: Access denied when retrieving secrets

**Solution**: Ensure RBAC role assignment exists:
```bash
az role assignment list --scope /subscriptions/.../providers/Microsoft.KeyVault/vaults/kv-personal-dev-eus2
```

### Compute Issues

**Problem**: VM creation fails with "SKU not available in region"

**Solution**: Change region or VM SKU:
```hcl
vm_location = "eastus2"  # Try different region
vm_size     = "Standard_B2s"  # Try permitted SKU
```

### Governance/Policy Issues

**Problem**: Policy assignment fails with "MissingSubscriptionScopedPermissions"

**Solution**: Ensure deploying principal has `Owner` or `Policy Contributor` role

### GitHub OIDC Issues

**Problem**: GitHub Actions auth fails with "AADSTS7000218: invalid_client"

**Solution**: Verify federated credentials:
```bash
az ad app federated-credential list --id <app-id> \
  --query "[].{displayName:displayName, subject:subject}" -o table
```

---

**End of Module Reference Guide**

For module-specific questions, see individual module `README.md` files in their directories.
