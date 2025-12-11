# Check Point CloudGuard Network Security Management Server & Security Gateway (Standalone) Master Terraform module for AWS

Terraform module which deploys a Check Point CloudGuard Network Security Gateway & Management (Standalone) instance into a new VPC.

These types of Terraform resources are supported:
* [AWS Instance](https://www.terraform.io/docs/providers/aws/r/instance.html)
* [VPC](https://www.terraform.io/docs/providers/aws/r/vpc.html)
* [Security group](https://www.terraform.io/docs/providers/aws/r/security_group.html)
* [Network interface](https://www.terraform.io/docs/providers/aws/r/network_interface.html)
* [Route](https://www.terraform.io/docs/providers/aws/r/route.html)
* [EIP](https://www.terraform.io/docs/providers/aws/r/eip.html) - conditional creation

This solution uses the following modules:
- standalone
- amis
- vpc

## Usage
Follow best practices for using CGNS modules on [the root page](https://registry.terraform.io/modules/checkpointsw/cloudguard-network-security/aws/latest#:~:text=Best%20Practices%20for%20Using%20Our%20Modules).


- Create or modify the deployment:
    - Due to terraform limitation, the apply command is:
    ```
    terraform apply -target=module.{module_name}.aws_route_table.private_subnet_rtb -auto-approve && terraform apply 
    ```
    

**Example:**
```
provider "aws" {}

module "example_module" {

    source  = "CheckPointSW/cloudguard-network-security/aws//modules/standalone_master"
    version = "1.0.5"

    // --- VPC Network Configuration ---
    vpc_cidr = "10.0.0.0/16"
    public_subnets_map = {
      "us-east-1a" = 1
    }
    private_subnets_map = {
      "us-east-1a" = 2
    }
    subnets_bit_length = 8

    // --- EC2 Instance Configuration ---
    standalone_name = "Check-Point-Standalone-tf"
    standalone_instance_type = "c5.xlarge"
    key_name = "publickey"
    allocate_and_associate_eip = true
    volume_size = 100
    volume_encryption = "alias/aws/ebs"
    enable_instance_connect = false
    disable_instance_termination = false
    instance_tags = {
      key1 = "value1"
      key2 = "value2"
    }

    // --- Check Point Settings ---
    standalone_version = "R81.20-BYOL"
    admin_shell = "/etc/cli.sh"
    standalone_password_hash = ""
    standalone_maintenance_mode_password_hash = ""

    // --- Advanced Settings ---
    resources_tag_name = "tag-name"
    standalone_hostname = "standalone-tf"
    allow_upload_download = true
    enable_cloudwatch = false
    standalone_bootstrap_script = "echo 'this is bootstrap script' > /home/admin/bootstrap.txt"
    primary_ntp = ""
    secondary_ntp = ""
    admin_cidr = "0.0.0.0/0"
    gateway_addresses = "0.0.0.0/0"
}
  ```

- Conditional creation
  - To create an Elastic IP and associate it to the Standalone instance:
  ```
  allocate_and_associate_eip = true
  ```
  



## Inputs
| Name                                      | Description                                                                                                                                           | Type        | Allowed Values                                                                                                      |
|-------------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------|-------------|--------------------------------------------------------------------------------------------------------------------|
| vpc_cidr                                  | The CIDR block of the VPC                                                                                                                             | string      |                                                                                                                 |
| public_subnets_map                        | A map of pairs {availability-zone = subnet-suffix-number}. Each entry creates a subnet. Minimum 1 pair.                                               | map         |                                                                                                                 |
| private_subnets_map                       | A map of pairs {availability-zone = subnet-suffix-number}. Each entry creates a subnet. Minimum 1 pair.                                               | map         |                                                                                                                 |
| subnets_bit_length                        | Number of additional bits with which to extend the VPC CIDR                                                                                           | number      |                                                                                                                 |
| standalone_name                           | The name tag of the Security Gateway & Management (Standalone) instance                                                                               | string      |**Default:** Check-Point-Standalone-tf                                                                      |
| standalone_instance_type                  | The instance type of the Security Gateway & Management (Standalone) instance                                                                          | string      | - c4.large <br/> - c4.xlarge <br/> - c5.large <br/> - c5.xlarge <br/> - c5.2xlarge <br/> - c5.4xlarge <br/> - c5.9xlarge <br/> - c5.12xlarge <br/> - c5.18xlarge <br/> - c5.24xlarge <br/> - c5n.large <br/> - c5n.xlarge <br/> - c5n.2xlarge <br/> - c5n.4xlarge <br/> - c5n.9xlarge <br/>  - c5n.18xlarge <br/>  - c5d.large <br/> - c5d.xlarge <br/> - c5d.2xlarge <br/> - c5d.4xlarge <br/> - c5d.9xlarge <br/> - c5d.12xlarge <br/>  - c5d.18xlarge <br/>  - c5d.24xlarge <br/> - m5.large <br/> - m5.xlarge <br/> - m5.2xlarge <br/> - m5.4xlarge <br/> - m5.8xlarge <br/> - m5.12xlarge <br/> - m5.16xlarge <br/> - m5.24xlarge <br/> - m6i.large <br/> - m6i.xlarge <br/> - m6i.2xlarge <br/> - m6i.4xlarge <br/> - m6i.8xlarge <br/> - m6i.12xlarge <br/> - m6i.16xlarge <br/> - m6i.24xlarge <br/> - m6i.32xlarge <br/> - c6i.large <br/> - c6i.xlarge <br/> - c6i.2xlarge <br/> - c6i.4xlarge <br/> - c6i.8xlarge <br/> - c6i.12xlarge <br/> - c6i.16xlarge <br/> - c6i.24xlarge <br/> - c6i.32xlarge <br/> - c6in.large <br/> - c6in.xlarge <br/> - c6in.2xlarge <br/> - c6in.4xlarge <br/> - c6in.8xlarge <br/> - c6in.12xlarge <br/> - c6in.16xlarge <br/> - c6in.24xlarge <br/> - c6in.32xlarge <br/> - r5.large <br/> - r5.xlarge <br/> - r5.2xlarge <br/> - r5.4xlarge <br/> - r5.8xlarge <br/> - r5.12xlarge <br/> - r5.16xlarge <br/> - r5.24xlarge <br/> - r5a.large <br/> - r5a.xlarge <br/> - r5a.2xlarge <br/> - r5a.4xlarge <br/> - r5a.8xlarge <br/> - r5a.12xlarge <br/> - r5a.16xlarge <br/> - r5a.24xlarge <br/> - r5b.large <br/> - r5b.xlarge <br/> - r5b.2xlarge <br/> - r5b.4xlarge <br/> - r5b.8xlarge <br/> - r5b.12xlarge <br/> - r5b.16xlarge <br/> - r5b.24xlarge <br/> - r5n.large <br/> - r5n.xlarge <br/> - r5n.2xlarge <br/> - r5n.4xlarge <br/> - r5n.8xlarge <br/> - r5n.12xlarge <br/> - r5n.16xlarge <br/> - r5n.24xlarge <br/> - r6i.large <br/> - r6i.xlarge <br/> - r6i.2xlarge <br/> - r6i.4xlarge <br/> - r6i.8xlarge <br/> - r6i.12xlarge <br/> - r6i.16xlarge <br/> - r6i.24xlarge <br/> - r6i.32xlarge <br/> - m6a.large <br/> - m6a.xlarge <br/> - m6a.2xlarge  <br/> - m6a.4xlarge <br/> - m6a.8xlarge <br/> - m6a.12xlarge <br/> - m6a.16xlarge <br/> - m6a.24xlarge <br/> - m6a.32xlarge <br/> - m6a.48xlarge <br/>**Default:** c5.xlarge                                 |
| key_name                                  | The EC2 Key Pair name to allow SSH access to the instances                                                                                            | string      |                                                                                                                 |
| allocate_and_associate_eip                | Allocate and associate an Elastic IP with the launched instance                                                                                       | bool        | true/false<br>**Default:** true                                                                                   |
| volume_size                               | Root volume size (GB)                                                                                                                                 | number      |**Default:** 100                                                                                           |
| volume_encryption                         | KMS or CMK key Identifier                                                                                                                             | string      |**Default:** alias/aws/ebs                                                                                 |
| enable_instance_connect                   | Enable SSH connection over AWS web console                                                                                                            | bool        | true/false<br>**Default:** false                                                                                   |
| disable_instance_termination              | Prevent accidental termination of the instance                                                                                                        | bool        | true/false<br>**Default:** false                                                                                   |
| metadata_imdsv2_required                  | Deploy instance with metadata v2 token required                                                                                                       | bool        | true/false<br>**Default:** true                                                                                    |
| instance_tags                             | A map of tags as key=value pairs.                                                                                                                     | map(string) |**Default:** {}                                                                                            |
| standalone_version                        | Security Gateway & Management (Standalone) version and license                                                                                       | string      | - R81.20-BYOL<br>- R82-PAYG-NGTP<br>**Default:** R81.20-BYOL                                                       |
| admin_shell                               | Set the admin shell to enable advanced command-line configuration                                                                                     | string      | - /etc/cli.sh<br>- /bin/bash<br>**Default:** /etc/cli.sh                                                           |
| standalone_password_hash                  | Admin user's password hash                                                                                                                            | string      |                                                                                                                 |
| resources_tag_name                        | (Optional)                                                                                                                                             | string      |                                                                                                                 |
| standalone_hostname                       | Security Gateway & Management (Standalone) prompt hostname                                                                                            | string      |                                                                                                                 |
| allow_upload_download                     | Automatically download Blade Contracts and other important data                                                                                       | bool        | true/false<br>**Default:** true                                                                                   |
| enable_cloudwatch                         | Report Check Point-specific CloudWatch metrics                                                                                                        | bool        | true/false<br>**Default:** false                                                                                   |
| standalone_bootstrap_script               | Semicolon (;) separated commands to run on the initial boot                                                                                           | string      |                                                                                                                 |
| primary_ntp                               | IPv4 address of Network Time Protocol primary server                                                                                                  | string      |**Default:** 169.254.169.123                                                                               |
| secondary_ntp                             | IPv4 address of Network Time Protocol secondary server                                                                                                | string      |**Default:** 0.pool.ntp.org                                                                                |
| admin_cidr                                | Allow web, SSH, and graphical clients from this network to communicate with the Management Server                                                    | string      |**Default:** 0.0.0.0/0                                                                                    |
| gateway_addresses                         | Allow gateways only from this network to communicate with the Management Server                                                                       | string      |**Default:** 0.0.0.0/0                                                                                    |
| standalone_maintenance_mode_password_hash | Maintenance-mode password hash                                                                                                                        | string      |                                                                                                                 |
 security_rules | List of security rules for ingress and egress.                                                         | list(object({<br/>    direction   = string    <br/>from_port   = any    <br/>to_port     = any <br/>protocol    = any <br/>cidr_blocks = list(any)<br/>}))         | **Default:** []|




## Outputs
To display the outputs defined by the module, create an `outputs.tf` file with the following structure:
```
output "instance_public_ip" {
  value = module.{module_name}.instance_public_ip
}
```
| Name                         | Description                                                                  |
|------------------------------|------------------------------------------------------------------------------|
| vpc_id                       | The id of the deployed vpc                                                   |
| internal_rtb_id              | The internal route table id                                                  |
| vpc_public_subnets_ids_list  | A list of the public subnets ids                                             |
| vpc_private_subnets_ids_list | A list of the private subnets ids                                            |
| standalone_instance_id       | The deployed Security Gateway & Management (Standalone) AWS instance id      |
| standalone_instance_name     | The deployed Security Gateway & Management (Standalone) AWS instance name    |
| standalone_public_ip         | The deployed Security Gateway & Management (Standalone) AWS public address   |
| standalone_ssh               | SSH command to the Security Gateway & Management (Standalone)                |
| standalone_url               | URL to the portal of the deployed Security Gateway & Management (Standalone) |
