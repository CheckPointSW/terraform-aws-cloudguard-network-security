# Check Point CloudGuard Network Multi-Domain Server Terraform module for AWS

Terraform module which deploys a Check Point CloudGuard Network Multi-Domain Server into an existing VPC.

These types of Terraform resources are supported:
* [AWS Instance](https://www.terraform.io/docs/providers/aws/r/instance.html)
* [Security Group](https://www.terraform.io/docs/providers/aws/r/security_group.html)
* [Network interface](https://www.terraform.io/docs/providers/aws/r/network_interface.html)
* [IAM Role](https://www.terraform.io/docs/providers/aws/r/iam_role.html) - conditional creation

See the [Multi-Domain Management Deployment on AWS](https://supportcenter.us.checkpoint.com/supportcenter/portal?eventSubmit_doGoviewsolutiondetails=&solutionid=sk143213) for additional information

This solution uses the following modules:
- amis
- cme_iam_role

## Usage
Follow best practices for using CGNS modules on [the root page](https://registry.terraform.io/modules/checkpointsw/cloudguard-network-security/aws/latest#:~:text=Best%20Practices%20for%20Using%20Our%20Modules).


**Example:**
```
provider "aws" {}

module "example_module" {

    source  = "CheckPointSW/cloudguard-network-security/aws//modules/mds"
    version = "1.0.4"
    
    // --- VPC Network Configuration ---
    vpc_id = "vpc-12345678"
    subnet_id = "subnet-abc123"
    
    // --- EC2 Instances Configuration ---
    mds_name = "CP-MDS-tf"
    mds_instance_type = "m5.12xlarge"
    key_name = "publickey"
    volume_size = 100
    volume_encryption = "alias/aws/ebs"
    enable_instance_connect = false
    disable_instance_termination = false
    instance_tags = {
      key1 = "value1"
      key2 = "value2"
    }
    
    // --- IAM Permissions ---
    iam_permissions = "Create with read permissions"
    predefined_role = ""
    sts_roles = []
    
    // --- Check Point Settings ---
    mds_version = "R81.20-BYOL"
    mds_admin_shell = "/etc/cli.sh"
    mds_password_hash = ""
    mds_maintenance_mode_password_hash = ""
    
    // --- Multi-Domain Server Settings ---
    mds_hostname = "mds-tf"
    mds_SICKey = ""
    allow_upload_download = "true"
    mds_installation_type = "Primary Multi-Domain Server"
    admin_cidr = "0.0.0.0/0"
    gateway_addresses = "0.0.0.0/0"
    primary_ntp = ""
    secondary_ntp = ""
    mds_bootstrap_script = "echo 'this is bootstrap script' > /home/admin/bootstrap.txt"
}
  ```

- Conditional creation
  - To create IAM Role:
  ```
  iam_permissions = "Create with read permissions" | "Create with read-write permissions" | "Create with assume role permissions (specify an STS role ARN)"
  and
  mds_installation_type = "Primary Multi-Domain Server"
  ```


## Inputs

| Name                               | Description                                                                                                                                                  | Type         | Allowed Values                                                                                      |
|------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------|--------------|----------------------------------------------------------------------------------------------------|
| vpc_id                             | The VPC ID in which to deploy                                                                                                                               | string       |                                                                                                 |
| subnet_id                          | Subnet with a route to the internet                                                                                                                         | string       |                                                                                                 |
| mds_name                           | (Optional) Name tag of the Multi-Domain Server                                                                                                              | string       | **Default:** Check-Point-MDS-tf                                                            |
| mds_instance_type                  | Instance type of the Multi-Domain Server                                                                                                                    | string       | - c4.large <br/> - c4.xlarge <br/> - c5.large <br/> - c5.xlarge <br/> - c5.2xlarge <br/> - c5.4xlarge <br/> - c5.9xlarge <br/> - c5.12xlarge <br/> - c5.18xlarge <br/> - c5.24xlarge <br/> - c5n.large <br/> - c5n.xlarge <br/> - c5n.2xlarge <br/> - c5n.4xlarge <br/> - c5n.9xlarge <br/>  - c5n.18xlarge <br/>  - c5d.large <br/> - c5d.xlarge <br/> - c5d.2xlarge <br/> - c5d.4xlarge <br/> - c5d.9xlarge <br/> - c5d.12xlarge <br/>  - c5d.18xlarge <br/>  - c5d.24xlarge <br/> - m5.large <br/> - m5.xlarge <br/> - m5.2xlarge <br/> - m5.4xlarge <br/> - m5.8xlarge <br/> - m5.12xlarge <br/> - m5.16xlarge <br/> - m5.24xlarge <br/> - m6i.large <br/> - m6i.xlarge <br/> - m6i.2xlarge <br/> - m6i.4xlarge <br/> - m6i.8xlarge <br/> - m6i.12xlarge <br/> - m6i.16xlarge <br/> - m6i.24xlarge <br/> - m6i.32xlarge <br/> - c6i.large <br/> - c6i.xlarge <br/> - c6i.2xlarge <br/> - c6i.4xlarge <br/> - c6i.8xlarge <br/> - c6i.12xlarge <br/> - c6i.16xlarge <br/> - c6i.24xlarge <br/> - c6i.32xlarge <br/> - c6in.large <br/> - c6in.xlarge <br/> - c6in.2xlarge <br/> - c6in.4xlarge <br/> - c6in.8xlarge <br/> - c6in.12xlarge <br/> - c6in.16xlarge <br/> - c6in.24xlarge <br/> - c6in.32xlarge <br/> - r5.large <br/> - r5.xlarge <br/> - r5.2xlarge <br/> - r5.4xlarge <br/> - r5.8xlarge <br/> - r5.12xlarge <br/> - r5.16xlarge <br/> - r5.24xlarge <br/> - r5a.large <br/> - r5a.xlarge <br/> - r5a.2xlarge <br/> - r5a.4xlarge <br/> - r5a.8xlarge <br/> - r5a.12xlarge <br/> - r5a.16xlarge <br/> - r5a.24xlarge <br/> - r5b.large <br/> - r5b.xlarge <br/> - r5b.2xlarge <br/> - r5b.4xlarge <br/> - r5b.8xlarge <br/> - r5b.12xlarge <br/> - r5b.16xlarge <br/> - r5b.24xlarge <br/> - r5n.large <br/> - r5n.xlarge <br/> - r5n.2xlarge <br/> - r5n.4xlarge <br/> - r5n.8xlarge <br/> - r5n.12xlarge <br/> - r5n.16xlarge <br/> - r5n.24xlarge <br/> - r6i.large <br/> - r6i.xlarge <br/> - r6i.2xlarge <br/> - r6i.4xlarge <br/> - r6i.8xlarge <br/> - r6i.12xlarge <br/> - r6i.16xlarge <br/> - r6i.24xlarge <br/> - r6i.32xlarge <br/> - m6a.large <br/> - m6a.xlarge <br/> - m6a.2xlarge  <br/> - m6a.4xlarge <br/> - m6a.8xlarge <br/> - m6a.12xlarge <br/> - m6a.16xlarge <br/> - m6a.24xlarge <br/> - m6a.32xlarge <br/> - m6a.48xlarge <br/>**Default:** m5.12xlarge                              |
| key_name                           | EC2 Key Pair name to allow SSH access                                                                                                                       | string       |                                                                                                 |
| volume_size                        | Root volume size (GB) - minimum 100                                                                                                                         | number       | **Default:** 100                                                                           |
| volume_encryption                  | KMS or CMK key identifier (e.g., alias/aws/ebs)                                                                                                            | string       | **Default:** alias/aws/ebs                                                                |
| enable_instance_connect            | Enable SSH connection over AWS web console                                                                                                                 | bool         | true/false<br>**Default:** false                                                                  |
| disable_instance_termination       | Prevent accidental termination                                                                                                                             | bool         | true/false<br>**Default:** false                                                                  |
| instance_tags                      | (Optional) Map of tags as key-value pairs                                                                                                                  | map(string)  |                                                                                                 |
| metadata_imdsv2_required           | Deploy instance with metadata v2 token required                                                                                                            | bool         | true/false<br>**Default:** true                                                                   |
| iam_permissions                    | IAM role to attach to instance profile                                                                                                                     | string       | - None<br>- Use existing<br>- Create with assume role permissions<br>- Create with read/write<br>**Default:** Create with read permissions |
| predefined_role                    | (Optional) Predefined IAM role (only applies with 'Use existing')                                                                                          | string       |                                                                                                 |
| sts_roles                          | (Optional) List of IAM roles for STS assumption (only applies with 'Create with assume role permissions')                                                   | list(string) |                                                                                                 |
| mds_version                        | Multi-Domain Server version and license                                                                                                                    | string       | - R81.10-BYOL<br>- R81.20-BYOL<br>- R82-BYOL<br>**Default:** R81.20-BYOL                           |
| mds_admin_shell                    | Set admin shell for advanced configurations                                                                                                                | string       | - /etc/cli.sh<br>- /bin/bash<br>- /bin/csh<br>**Default:** /etc/cli.sh                            |
| mds_password_hash                  | (Optional) Admin user's password hash                                                                                                                      | string       |                                                                                                 |
| mds_hostname                       | (Optional) Multi-Domain Server prompt hostname                                                                                                             | string       |                                                                                                 |
| mds_SICKey                         | Secure Internal Communication key for trusted connections                                                                                                  | string       |                                                                                                 |
| allow_upload_download              | Automatically download Blade Contracts and related data                                                                                                    | bool         | true/false<br>**Default:** true                                                                   |
| mds_installation_type              | Multi-Domain Server installation type                                                                                                                     | string       | - Primary Multi-Domain Server<br>- Secondary Multi-Domain Server<br>- Multi-Domain Log Server<br>**Default:** Primary Multi-Domain Server |
| admin_cidr                         | CIDR for allowing access to the Multi-Domain Server                                                                                                        | string       | valid CIDR<br>**Default:** 0.0.0.0/0                                                              |
| gateway_addresses                  | CIDR for allowing gateway access to the Multi-Domain Server                                                                                                | string       | valid CIDR<br>**Default:** 0.0.0.0/0                                                              |
| primary_ntp                        | (Optional) IPv4 address of the primary Network Time Protocol server                                                                                        | string       | **Default:** 169.254.169.123                                                              |
| secondary_ntp                      | (Optional) IPv4 address of the secondary Network Time Protocol server                                                                                      | string       | **Default:** 0.pool.ntp.org                                                               |
| mds_bootstrap_script               | (Optional) Semicolon-separated commands to run during initial boot                                                                                        | string       |                                                                                                 |
| mds_maintenance_mode_password_hash | (Optional) Admin user's password hash for maintenance mode                                                                                                 | string       |                                                                                                 |
 security_rules | List of security rules for ingress and egress.                                                         | list(object({<br/>    direction   = string    <br/>from_port   = any    <br/>to_port     = any <br/>protocol    = any <br/>cidr_blocks = list(any)<br/>}))         | **Default:** []|



## Outputs
To display the outputs defined by the module, create an `outputs.tf` file with the following structure:
```
output "instance_public_ip" {
  value = module.{module_name}.instance_public_ip
}
```
| Name              | Description                                        |
|-------------------|----------------------------------------------------|
| mds_instance_id   | The deployed Multi-Domain Server AWS instance id   |
| mds_instance_name | The deployed Multi-Domain Server AWS instance name |
| mds_instance_tags | The deployed Multi-Domain Server AWS tags          |
