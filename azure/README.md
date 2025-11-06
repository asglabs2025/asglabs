# Terraform Azure Infrastructure

## Overview
This repository provides a structured approach to managing Azure infrastructure using Terraform. It separates **environment configurations** from **reusable modules**, making it easy to deploy multiple environments consistently.

- **Environments:** Contains environment-specific Terraform configurations (e.g., dev, prod).  
- **Modules:** Contains reusable building blocks (resource-group, network, NIC, VM) that can be composed in environments.
- **State Storage:** This example stores Terraform state files in an Azure Storage Account container for secure state management.  
- **Terraform Variables:** See below for a sanitized `terraform.tfvars` example.

---

## Repository Structure

```text
terraform/azure/
├── environments/
│   └── dev/
│       ├── main.tf           # Environment-specific resources using modules
│       ├── variables.tf      # Input variables for the environment
│       ├── terraform.tfvars  # Environment-specific values
│       ├── outputs.tf        # Environment-specific outputs
│       └── backend.tf        # Remote state configuration (Azure Storage)
├── modules/
│   ├── network/              # VNet, subnets, NSGs
│   ├── nic/                  # Network interfaces
│   ├── resource-group/       # Resource group creation
│   └── vm/                   # Virtual machine module
└── README.md

---

## Usage

Run Terraform commands from the desired environment folder (e.g., dev):

cd terraform/azure/environments/dev

terraform init
terraform plan -var-file="terraform.tfvars"
terraform apply -var-file="terraform.tfvars"


## Terraform.tfvars example:
default_tags = {
  owner      = "your-name"
  managed_by = "terraform"
}

tags = {
  environment = "dev"
  project     = "azure-project"
}

azure_client_id       = "your-client-id"
azure_client_secret   = "your-client-secret"
azure_subscription_id = "your-subscription-id"
azure_tenant_id       = "your-tenant-id"

resource_group_name     = "your-rg-name"
resource_group_location = "YourRegion"

azure_vnet_name             = "your-vnet-name"
azure_vnet_address_space    = ["10.0.0.0/16"]
azure_subnet_name           = "your-subnet-name"
azure_subnet_address_prefix = ["10.0.1.0/24"]

azure_vm_name        = "your-vm-name"
azure_vm_size        = "Standard_B1s"
azure_admin_username = "your-username"
ssh_public_key_path  = "~/.ssh/id_rsa.pub"
os_storage_type      = "Standard_LRS"

image_publisher = "Canonical"
image_offer     = "UbuntuServer"
image_sku       = "18.04-LTS"
image_version   = "latest"

---
# Modules Overview

resource-group: Creates Azure resource groups.

network: Creates virtual networks and subnets.

nic: Creates network interfaces for VMs.

vm: Creates virtual machines.

Each module is reusable and can be combined to build full environments.

---
# Best Practices
Separate environments: Keep dev, test, and prod in separate folders.

Remote state: Use Azure Storage (or another remote backend) for Terraform state.

Sensitive data: Do not commit secrets. Use .gitignore for terraform.tfvars files containing credentials.

Reusability: Write modules for common infrastructure patterns to avoid duplication.

Version control: Tag module versions and pin provider versions in versions.tf.
