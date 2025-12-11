# Check Point CloudGuard Network Transit Gateway Auto Scaling Group Master Terraform module for AWS

Terraform module which deploys a Check Point CloudGuard Network Security Gateway Auto Scaling Group for Transit Gateway with an optional Management Server in a new VPC.

These types of Terraform resources are supported:
* [VPC](https://www.terraform.io/docs/providers/aws/r/vpc.html)
* [Subnet](https://www.terraform.io/docs/providers/aws/r/subnet.html)
* [AWS Instance](https://www.terraform.io/docs/providers/aws/r/instance.html)
* [Security Group](https://www.terraform.io/docs/providers/aws/r/security_group.html)
* [Network interface](https://www.terraform.io/docs/providers/aws/r/network_interface.html)
* [CloudWatch Metric Alarm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm)
* [EIP](https://www.terraform.io/docs/providers/aws/r/eip.html)
* [Launch template](https://www.terraform.io/docs/providers/aws/r/launch_template.html)
* [Auto Scaling Group](https://www.terraform.io/docs/providers/aws/r/autoscaling_group.html)
* [IAM Role](https://www.terraform.io/docs/providers/aws/r/iam_role.html) - conditional creation

See the [CloudGuard Network for AWS Transit Gateway R80.10 and Higher Deployment Guide](https://sc1.checkpoint.com/documents/IaaS/WebAdminGuides/EN/CP_CloudGuard_AWS_Transit_Gateway/Content/Topics-AWS-TGW-R80-10-AG/Introduction.htm) for additional information

This solution uses the following modules:
- tgw_asg
- autoscale
- management
- cme_iam_role
- vpc

## Usage
Follow best practices for using CGNS modules on [the root page](https://registry.terraform.io/modules/checkpointsw/cloudguard-network-security/aws/latest#:~:text=Best%20Practices%20for%20Using%20Our%20Modules).


**Example:**
```
provider "aws" {}

module "example_module" {

    source  = "CheckPointSW/cloudguard-network-security/aws//modules/tgw_asg_master"
    version = "1.0.5"
  
    // --- Network Configuration ---
    vpc_cidr = "10.0.0.0/16"
    public_subnets_map = {
    "us-east-1a" = 1
    "us-east-1b" = 2
    }
    subnets_bit_length = 8
    
    // --- General Settings ---
    key_name = "publickey"
    enable_volume_encryption = true
    enable_instance_connect = false
    disable_instance_termination = false
    allow_upload_download = true
    
    // --- Check Point CloudGuard Network Security Gateways Auto Scaling Group Configuration ---
    gateway_name = "Check-Point-gateway"
    gateway_instance_type = "c5.xlarge"
    gateways_min_group_size = 2
    gateways_max_group_size = 8
    gateway_version = "R81.20-BYOL"
    gateway_password_hash = ""
    gateway_maintenance_mode_password_hash = "" # For R81.10 and below the gateway_password_hash is used also as maintenance-mode password.
    gateway_SICKey = "12345678"
    enable_cloudwatch = true
    asn = "6500"
    
    // --- Check Point CloudGuard Network Security Management Server Configuration ---
    management_deploy = true
    management_instance_type = "m5.xlarge"
    management_version = "R81.20-BYOL"
    management_password_hash = ""
    management_maintenance_mode_password_hash = "" # For R81.10 and below the management_password_hash is used also as maintenance-mode password.
    management_permissions = "Create with read-write permissions"
    management_predefined_role = ""
    gateways_blades = true
    admin_cidr = "0.0.0.0/0"
    gateways_addresses = "0.0.0.0/0"
    gateway_management = "Locally managed"
    
    // --- Automatic Provisioning with Security Management Server Settings ---
    control_gateway_over_public_or_private_address = "private"
    management_server = "management-server"
    configuration_template = "template-name"
}
```

  - Conditional creation
    - To create a Security Management server with IAM Role:
```
  management_permissions = "Create with read permissions" | "Create with read-write permissions" | "Create with assume role permissions (specify an STS role ARN)"
```
  - To enable cloudwatch for ASG:
```
  enable_cloudwatch = true
```
  Note: enabling cloudwatch will automatically create IAM role with cloudwatch:PutMetricData permission
  - To deploy Security Management Server:
```
  management_deploy = true
```


## Inputs

| Name                                      | Description                                                                                                                        | Type         | Allowed Values                                                                                         |
|-------------------------------------------|------------------------------------------------------------------------------------------------------------------------------------|--------------|-------------------------------------------------------------------------------------------------------|
| vpc_cidr                                  | The CIDR block of the VPC                                                                                                         | string       |                                                                                                    |
| public_subnets_map                        | Map of pairs {availability-zone = subnet-suffix-number}. Minimum 2 pairs required                                                | map          |                                                                                                    |
| subnets_bit_length                        | Additional bits to extend the VPC CIDR                                                                                           | number       |                                                                                                    |
| key_name                                  | The EC2 Key Pair name to allow SSH access                                                                                        | string       |                                                                                                    |
| enable_volume_encryption                  | Encrypt Environment instances volume with AWS KMS key                                                                            | bool         | true/false<br>**Default:** true                                                                      |
| enable_instance_connect                   | Enable SSH over AWS web console ([Regions](https://aws.amazon.com/about-aws/whats-new/2019/06/introducing-amazon-ec2-instance-connect/)) | bool         | true/false<br>**Default:** false                                                                     |
| disable_instance_termination              | Prevent accidental termination                                                                                                   | bool         | true/false<br>**Default:** false                                                                     |
| metadata_imdsv2_required                  | Deploy instance with metadata v2 token required                                                                                  | bool         | true/false<br>**Default:** true                                                                      |
| allow_upload_download                     | Automatically download Blade Contracts and other important data                                                                  | bool         | true/false<br>**Default:** true                                                                      |
| gateway_name                              | (Optional) Name tag of the Security Gateway instances                                                                            | string       | **Default:** Check-Point-Gateway                                                             |
| gateway_instance_type                     | Instance type of the Security Gateways                                                                                          | string       | - c4.large <br/> - c4.xlarge <br/> - c5.large <br/> - c5.xlarge <br/> - c5.2xlarge <br/> - c5.4xlarge <br/> - c5.9xlarge <br/> - c5.12xlarge <br/> - c5.18xlarge <br/> - c5.24xlarge <br/> - c5n.large <br/> - c5n.xlarge <br/> - c5n.2xlarge <br/> - c5n.4xlarge <br/> - c5n.9xlarge <br/>  - c5n.18xlarge <br/>  - c5d.large <br/> - c5d.xlarge <br/> - c5d.2xlarge <br/> - c5d.4xlarge <br/> - c5d.9xlarge <br/> - c5d.12xlarge <br/>  - c5d.18xlarge <br/>  - c5d.24xlarge <br/> - m5.large <br/> - m5.xlarge <br/> - m5.2xlarge <br/> - m5.4xlarge <br/> - m5.8xlarge <br/> - m5.12xlarge <br/> - m5.16xlarge <br/> - m5.24xlarge <br/> - m6i.large <br/> - m6i.xlarge <br/> - m6i.2xlarge <br/> - m6i.4xlarge <br/> - m6i.8xlarge <br/> - m6i.12xlarge <br/> - m6i.16xlarge <br/> - m6i.24xlarge <br/> - m6i.32xlarge <br/> - c6i.large <br/> - c6i.xlarge <br/> - c6i.2xlarge <br/> - c6i.4xlarge <br/> - c6i.8xlarge <br/> - c6i.12xlarge <br/> - c6i.16xlarge <br/> - c6i.24xlarge <br/> - c6i.32xlarge <br/> - c6in.large <br/> - c6in.xlarge <br/> - c6in.2xlarge <br/> - c6in.4xlarge <br/> - c6in.8xlarge <br/> - c6in.12xlarge <br/> - c6in.16xlarge <br/> - c6in.24xlarge <br/> - c6in.32xlarge <br/> - r5.large <br/> - r5.xlarge <br/> - r5.2xlarge <br/> - r5.4xlarge <br/> - r5.8xlarge <br/> - r5.12xlarge <br/> - r5.16xlarge <br/> - r5.24xlarge <br/> - r5a.large <br/> - r5a.xlarge <br/> - r5a.2xlarge <br/> - r5a.4xlarge <br/> - r5a.8xlarge <br/> - r5a.12xlarge <br/> - r5a.16xlarge <br/> - r5a.24xlarge <br/> - r5b.large <br/> - r5b.xlarge <br/> - r5b.2xlarge <br/> - r5b.4xlarge <br/> - r5b.8xlarge <br/> - r5b.12xlarge <br/> - r5b.16xlarge <br/> - r5b.24xlarge <br/> - r5n.large <br/> - r5n.xlarge <br/> - r5n.2xlarge <br/> - r5n.4xlarge <br/> - r5n.8xlarge <br/> - r5n.12xlarge <br/> - r5n.16xlarge <br/> - r5n.24xlarge <br/> - r6i.large <br/> - r6i.xlarge <br/> - r6i.2xlarge <br/> - r6i.4xlarge <br/> - r6i.8xlarge <br/> - r6i.12xlarge <br/> - r6i.16xlarge <br/> - r6i.24xlarge <br/> - r6i.32xlarge <br/> - m6a.large <br/> - m6a.xlarge <br/> - m6a.2xlarge  <br/> - m6a.4xlarge <br/> - m6a.8xlarge <br/> - m6a.12xlarge <br/> - m6a.16xlarge <br/> - m6a.24xlarge <br/> - m6a.32xlarge <br/> - m6a.48xlarge <br/>**Default:** c5.xlarge                                                  |
| gateways_min_group_size                   | Minimum number of Security Gateways                                                                                              | number       | **Default:** 2                                                                               |
| gateways_max_group_size                   | Maximum number of Security Gateways                                                                                              | number       | **Default:** 10                                                                              |
| gateway_version                           | Gateway version and license                                                                                                      | string       | - R81.20-BYOL<br>- R82-PAYG<br>**Default:** R81.20-BYOL                                              |
| gateway_password_hash                     | (Optional) Admin user's password hash                                                                                           | string       |                                                                                                    |
| gateway_SIC_Key                           | Secure Internal Communication key                                                                                               | string       | **Default:** "12345678"                                                                       |
| enable_cloudwatch                         | Report Check Point-specific CloudWatch metrics                                                                                  | bool         | true/false<br>**Default:** false                                                                     |
| asn                                       | Organization Autonomous System Number (ASN)                                                                                     | string       | **Default:** 6500                                                                             |
| management_deploy                         | Deploy or use an existing Security Management Server                                                                             | bool         | true/false<br>**Default:** true                                                                      |
| management_instance_type                  | Instance type of the Security Management Server                                                                                 | string       | - c4.large <br/> - c4.xlarge <br/> - c5.large <br/> - c5.xlarge <br/> - c5.2xlarge <br/> - c5.4xlarge <br/> - c5.9xlarge <br/> - c5.12xlarge <br/> - c5.18xlarge <br/> - c5.24xlarge <br/> - c5n.large <br/> - c5n.xlarge <br/> - c5n.2xlarge <br/> - c5n.4xlarge <br/> - c5n.9xlarge <br/>  - c5n.18xlarge <br/>  - c5d.large <br/> - c5d.xlarge <br/> - c5d.2xlarge <br/> - c5d.4xlarge <br/> - c5d.9xlarge <br/> - c5d.12xlarge <br/>  - c5d.18xlarge <br/>  - c5d.24xlarge <br/> - m5.large <br/> - m5.xlarge <br/> - m5.2xlarge <br/> - m5.4xlarge <br/> - m5.8xlarge <br/> - m5.12xlarge <br/> - m5.16xlarge <br/> - m5.24xlarge <br/> - m6i.large <br/> - m6i.xlarge <br/> - m6i.2xlarge <br/> - m6i.4xlarge <br/> - m6i.8xlarge <br/> - m6i.12xlarge <br/> - m6i.16xlarge <br/> - m6i.24xlarge <br/> - m6i.32xlarge <br/> - c6i.large <br/> - c6i.xlarge <br/> - c6i.2xlarge <br/> - c6i.4xlarge <br/> - c6i.8xlarge <br/> - c6i.12xlarge <br/> - c6i.16xlarge <br/> - c6i.24xlarge <br/> - c6i.32xlarge <br/> - c6in.large <br/> - c6in.xlarge <br/> - c6in.2xlarge <br/> - c6in.4xlarge <br/> - c6in.8xlarge <br/> - c6in.12xlarge <br/> - c6in.16xlarge <br/> - c6in.24xlarge <br/> - c6in.32xlarge <br/> - r5.large <br/> - r5.xlarge <br/> - r5.2xlarge <br/> - r5.4xlarge <br/> - r5.8xlarge <br/> - r5.12xlarge <br/> - r5.16xlarge <br/> - r5.24xlarge <br/> - r5a.large <br/> - r5a.xlarge <br/> - r5a.2xlarge <br/> - r5a.4xlarge <br/> - r5a.8xlarge <br/> - r5a.12xlarge <br/> - r5a.16xlarge <br/> - r5a.24xlarge <br/> - r5b.large <br/> - r5b.xlarge <br/> - r5b.2xlarge <br/> - r5b.4xlarge <br/> - r5b.8xlarge <br/> - r5b.12xlarge <br/> - r5b.16xlarge <br/> - r5b.24xlarge <br/> - r5n.large <br/> - r5n.xlarge <br/> - r5n.2xlarge <br/> - r5n.4xlarge <br/> - r5n.8xlarge <br/> - r5n.12xlarge <br/> - r5n.16xlarge <br/> - r5n.24xlarge <br/> - r6i.large <br/> - r6i.xlarge <br/> - r6i.2xlarge <br/> - r6i.4xlarge <br/> - r6i.8xlarge <br/> - r6i.12xlarge <br/> - r6i.16xlarge <br/> - r6i.24xlarge <br/> - r6i.32xlarge <br/> - m6a.large <br/> - m6a.xlarge <br/> - m6a.2xlarge  <br/> - m6a.4xlarge <br/> - m6a.8xlarge <br/> - m6a.12xlarge <br/> - m6a.16xlarge <br/> - m6a.24xlarge <br/> - m6a.32xlarge <br/> - m6a.48xlarge <br/>**Default:** m5.xlarge                                                  |
| management_version                        | License for the Security Management Server                                                                                      | string       | - R81.10-BYOL<br>- R82-BYOL<br>**Default:** R81.20-BYOL                                              |
| management_password_hash                  | (Optional) Admin user's password hash                                                                                           | string       |                                                                                                    |
| management_permissions                    | IAM role for the instance profile                                                                                               | string       | - None<br>- Use existing<br>- Create with read-write permissions<br>**Default:** Create with read-write permissions |
| gateways_blades                           | Enable Intrusion Prevention System, Application Control, and other blades                                                       | bool         | true/false<br>**Default:** true                                                                      |
| admin_cidr                                | Allow web, SSH, and graphical clients only from this network                                                                    | string       |                                                                                                    |
| gateway_addresses                         | Allow gateways only from this network                                                                                           | string       |                                                                                                    |
| gateway_management                        | Select 'Over the internet' for non-private IP-managed gateways                                                                  | string       | - Locally managed<br>- Over the internet<br>**Default:** Locally managed                             |
| control_gateway_over_public_or_private_address | Use private or public address for gateways                                                                                      | string       | - private<br>- public<br>**Default:** private                                                        |
| management_server                         | (Optional) Name representing the Security Management Server                                                                     | string       | **Default:** management-server                                                               |
| configuration_template                    | (Optional) Security Gateway configuration template                                                                              | string       | **Default:** TGW-ASG-configuration                                                           |
| gateway_maintenance_mode_password_hash    | Maintenance-mode password hash                                                                                                  | string       |                                                                                                    |
| management_maintenance_mode_password_hash | Maintenance-mode password hash for the Security Management Server                                                              | string       |                                                                                                    |


## Outputs
To display the outputs defined by the module, create an `outputs.tf` file with the following structure:
```
output "instance_public_ip" {
  value = module.{module_name}.instance_public_ip
}
```
| Name                     | Description                                                                                                                                                                                                                                                 |
|--------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| vpc_id                   | The id of the deployed vpc                                                                                                                                                                                                                                  |
| public_subnets_ids_list  | A list of the public subnets ids                                                                                                                                                                                                                            |
| management_instance_name | The deployed Security Management AWS instance name                                                                                                                                                                                                          |
| management_public_ip     | The deployed Security Management Server AWS public ip                                                                                                                                                                                                       |
| management_url           | URL to the portal of the deployed Security Management Server                                                                                                                                                                                                |
| autoscaling_group_name   | The name of the deployed AutoScaling Group                                                                                                                                                                                                                  |
| configuration_template   | The name that represents the configuration template. Configurations required to automatically provision the Gateways in the Auto Scaling Group, such as what Security Policy to install and which Blades to enable, will be placed under this template name |
| controller_name          | The name that represents the controller. Configurations required to connect to your AWS environment, such as credentials and regions, will be placed under this controller name                                                                             | 
