![GitHub Wachers](https://img.shields.io/github/watchers/checkpointsw/terraform-aws-cloudguard-network-security)
![GitHub Release](https://img.shields.io/github/v/release/checkpointsw/terraform-aws-cloudguard-network-security)
![GitHub Commits Since Last Commit](https://img.shields.io/github/commits-since/checkpointsw/terraform-aws-cloudguard-network-security/latest/master)
![GitHub Last Commit](https://img.shields.io/github/last-commit/checkpointsw/terraform-aws-cloudguard-network-security/master)
![GitHub Repo Size](https://img.shields.io/github/repo-size/checkpointsw/terraform-aws-cloudguard-network-security)
![GitHub Downloads](https://img.shields.io/github/downloads/checkpointsw/terraform-aws-cloudguard-network-security/total)

# Terraform Modules for CloudGuard Network Security (CGNS) - AWS

## Introduction
This repository provides a structured set of Terraform modules for deploying Check Point CloudGuard Network Security in Amazon Web Services (AWS). These modules automate the creation of Virtual Private Clouds (VPCs), Security Gateways, High-Availability architectures, and more, enabling secure and scalable cloud deployments.

## Repository Structure
`Submodules`: Contains modular, reusable, production-grade Terraform components, each with its own documentation.

`Examples`: Demonstrates how to use the modules.

## Available Submodules

**Submodules:**
* [`autoscale_gwlb`](https://registry.terraform.io/modules/checkpointsw/cloudguard-network-security/aws/latest/submodules/autoscale_gwlb) - Deploys Auto Scaling Group of  CloudGuard Security Gateways into an existing VPC.
* [`cme_iam_role`](https://registry.terraform.io/modules/checkpointsw/cloudguard-network-security/aws/latest/submodules/cme_iam_role) - Creates AWS IAM Role for Cloud Management Extension (CME) on Security Management Server.
* [`cme_iam_role_gwlb`](https://registry.terraform.io/modules/checkpointsw/cloudguard-network-security/aws/latest/submodules/cme_iam_role_gwlb) - Creates AWS IAM Role for Cloud Management Extension (CME) manages Gateway Load Balancer Auto Scale Group on Security Management Server.
* [`gateway`](https://registry.terraform.io/modules/checkpointsw/cloudguard-network-security/aws/latest/submodules/gateway) - Deploys Check Point CloudGuard Network Security Gateway into an existing VPC.
* [`gateway_master`](https://registry.terraform.io/modules/checkpointsw/cloudguard-network-security/aws/latest/submodules/gateway_master) -Check Point CloudGuard Network Security Gateway into a new VPC.
* [`gwlb`](https://registry.terraform.io/modules/checkpointsw/cloudguard-network-security/aws/latest/submodules/gwlb) - Deploys AWS Auto Scaling group configured for Gateway Load Balancer into an existing VPC.
* [`gwlb_master`](https://registry.terraform.io/modules/checkpointsw/cloudguard-network-security/aws/latest/submodules/gwlb_master) - Deploys AWS Auto Scaling group configured for Gateway Load Balancer into a new VPC.
* [`management`](https://registry.terraform.io/modules/checkpointsw/cloudguard-network-security/aws/latest/submodules/management) - Deploys CloudGuard Network Security Management Server into an existing VPC.

**Internal Submodules:**
* [`amis`](https://registry.terraform.io/modules/checkpointsw/cloudguard-network-security/aws/latest/submodules/amis)
* [`cloudwatch_policy`](https://registry.terraform.io/modules/checkpointsw/cloudguard-network-security/aws/latest/submodules/cloudwatch_policy)
* [`elastic_ip`](https://registry.terraform.io/modules/checkpointsw/cloudguard-network-security/aws/latest/submodules/common/elastic_ip)
* [`gateway_instance`](https://registry.terraform.io/modules/checkpointsw/cloudguard-network-security/aws/latest/submodules/common/gateway_instance)
* [`instance_type`](https://registry.terraform.io/modules/checkpointsw/cloudguard-network-security/aws/latest/submodules/common/instance_type)
* [`internal_default_route`](https://registry.terraform.io/modules/checkpointsw/cloudguard-network-security/aws/latest/submodules/common/internal_default_route)
* [`load_balancer`](https://registry.terraform.io/modules/checkpointsw/cloudguard-network-security/aws/latest/submodules/common/load_balancer)
* [`permissive_sg`](https://registry.terraform.io/modules/checkpointsw/cloudguard-network-security/aws/latest/submodules/common/permissive_sg)
* [`version_license`](https://registry.terraform.io/modules/checkpointsw/cloudguard-network-security/aws/latest/submodules/common/version_license)
* [`vpc`](https://registry.terraform.io/modules/checkpointsw/cloudguard-network-security/aws/latest/submodules/vpc)

***
# AWS Terraform Security Group Configuration

## Default Security Rules
Each submodule in this repository includes **preconfigured security group rules** designed to ensure the solution works properly out of the box. These rules are tailored for the default deployment scenarios but may require adjustments to meet your specific security and compliance requirements.

**Example:** To restrict inbound\outbound traffic, update the security_rules attribute in the submodule configuration:

```hcl
  security_rules = [
    {
      direction   = "ingress"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["10.0.0.0/30"]
    }
  ]
```
# Best Practices for Using CloudGuard Modules

## Step 1: Use the Required Module
Add the required module in your Terraform configuration file (`main.tf`) to deploy resources. For example:

```hcl
provider "aws" { }

module "example_module" {
  source  = "CheckPointSW/cloudguard-network-security/aws//modules/{module_name}"
  version = "{chosen_version}"
  # Add the required inputs
}
```
---

## Step 2: Open the Terminal
Ensure you have the AWS CLI installed and navigate to the directory containing your main.tf file: is located, using the appropriate terminal: 

- **Linux/macOS**: **Terminal**.
- **Windows**: **PowerShell** or **Command Prompt**.

---

## Step 3: Set Environment Variables and Log in with AWS CLI
Set up your AWS credentials and configure the default region by setting environment variables:


### Linux/macOS
```hcl
export AWS_ACCESS_KEY_ID="{your-access-key-id}"
export AWS_SECRET_ACCESS_KEY="{your-secret-access-key}"
export AWS_DEFAULT_REGION="{your-region}"

aws configure

```
### PowerShell (Windows)
```hcl
$env:AWS_ACCESS_KEY_ID="{your-access-key-id}"
$env:AWS_SECRET_ACCESS_KEY="{your-secret-access-key}"
$env:AWS_DEFAULT_REGION="{your-region}"

aws configure
```
### Command Prompt (Windows)
```hcl
set AWS_ACCESS_KEY_ID="{your-access-key-id}"
set AWS_SECRET_ACCESS_KEY="{your-secret-access-key}"
set AWS_DEFAULT_REGION="{your-region}"

aws configure
```
---


## Step 4: Deploy with Terraform
Use Terraform commands to deploy resources securely.

### Initialize Terraform
Prepare the working directory and download required provider plugins:
```hcl
terraform init
```

### Plan Deployment
Preview the changes Terraform will make:
```hcl
terraform plan
```
### Apply Deployment
Apply the planned changes and deploy the resources:
```hcl
terraform apply
```
Note: The terraform apply command might vary slightly depending on the submodule configurations. Pay close attention to any additional instructions provided in the submodules' documentation to ensure correct usage and handling of the resources.