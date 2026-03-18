# Personal Azure Environment — Dev
project_name = "personal"
environment  = "dev"
location     = "eastus2"

# Networking
address_space = "10.0.0.0/16"
subnet_prefix = "10.0.1.0/24"

# Owner & Contact
owner_email           = "matt.bouges@gmail.com"   # UPDATE: Replace with your email
budget_contact_emails = ["matt.bouges@gmail.com"] # UPDATE: Replace with your email

# Budget
budget_amount = 10

# Governance — allowed regions and VM sizes
allowed_locations = ["eastus2", "eastus"]
# allowed_vm_skus uses defaults (B-series + small D-series) — override here if needed

# GitHub Actions CI/CD
github_org      = "mbouges"
github_repo     = "my-azure-infra"
owner_object_id = "b53807db-aa6a-4e20-a1f6-7e0e93236c08"
