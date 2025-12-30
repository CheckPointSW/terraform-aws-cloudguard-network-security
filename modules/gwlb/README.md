# Check Point CloudGuard Network Gateway Load Balancer Terraform module for AWS

Terraform module which deploys an AWS Auto Scaling group configured for Gateway Load Balancer into an existing VPC.

These types of Terraform resources are supported:
* [AWS Instance](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance)
* [Security Group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group)
* [Load Balancer](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb)
* [Load Balancer Target Group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group)
* [Launch template](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_template)
* [Auto Scaling Group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group)
* [IAM Role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) - conditional creation

See the [Check Point CloudGuard Gateway Load Balancer on AWS](https://sc1.checkpoint.com/documents/IaaS/WebAdminGuides/EN/CP_CloudGuard_Network_for_AWS_Centralized_Gateway_Load_Balancer/Content/Topics-AWS-GWLB-VPC-DG/Introduction.htm) for additional information

This solution uses the following modules:
- autoscale_gwlb
- management
- cme_iam_role_gwlb
- amis

## Usage
Follow best practices for using CGNS modules on [the root page](https://registry.terraform.io/modules/checkpointsw/cloudguard-network-security/aws/latest#:~:text=Best%20Practices%20for%20Using%20Our%20Modules).


**Example:**
```
provider "aws" {}

module "example_module" {

    source  = "CheckPointSW/cloudguard-network-security/aws//modules/gwlb"
    version = "1.0.5"

        // --- VPC Network Configuration ---
    vpc_id = "vpc-12345"
    subnet_ids = ["subnet-123457", "subnet-123456"]
        
    // --- General Settings ---
    key_name = "publickey"
    enable_volume_encryption = true
    volume_size = 200
    enable_instance_connect = false
    disable_instance_termination = false
    allow_upload_download = true
    management_server = "CP-Management-gwlb-tf"
    configuration_template = "gwlb-configuration"
    admin_shell = "/etc/cli.sh"
        
    // --- Gateway Load Balancer Configuration ---
    gateway_load_balancer_name = "gwlb1"
    target_group_name = "tg1"
    connection_acceptance_required = "false"
    enable_cross_zone_load_balancing = "true"
        
    // --- Check Point CloudGuard IaaS Security Gateways Auto Scaling Group Configuration ---
    gateway_name = "Check-Point-GW-tf"
    gateway_instance_type = "c5.xlarge"
    minimum_group_size = 2
    maximum_group_size = 10
    gateway_version = "R81.20-BYOL"
    gateway_password_hash = ""
    gateway_maintenance_mode_password_hash = "" # For R81.10 and below the gateway_password_hash is used also as maintenance-mode password.
    gateway_SICKey = "12345678"
    gateways_provision_address_type = "private"
    allocate_public_IP = false
    enable_cloudwatch = false
    gateway_bootstrap_script = "echo 'this is bootstrap script' > /home/admin/bootstrap.txt"
        
    // --- Check Point CloudGuard IaaS Security Management Server Configuration ---
    management_deploy = true
    management_instance_type = "m5.xlarge"
    management_version = "R81.20-BYOL"
    management_password_hash = ""
    management_maintenance_mode_password_hash = "" # For R81.10 and below the management_password_hash is used also as maintenance-mode password.
    gateways_policy = "Standard"
    gateway_management = "Locally managed"
    admin_cidr = ""
    gateways_addresses = ""
        
    // --- Other parameters ---
    volume_type = "gp3"       
}
```


- Conditional creation
  - To enable cloudwatch for GWLB:
  ```
  enable_cloudwatch = true
  ```
  Note: enabling cloudwatch will automatically create IAM role with cloudwatch:PutMetricData permission
  - To deploy Security Management Server:
  ```
  management_deploy = true
  ```


## Inputs
| Name                   | Description                                                                                                 | Type   | Allowed Values                                                                                                           |
|------------------------|-------------------------------------------------------------------------------------------------------------|--------|-------------------------------------------------------------------------------------------------------------------------|
| vpc_id                | Select an existing VPC                                                                                     | string |                                                                                                                      |
| subnet_ids            | The VPC subnets ID                                                                                        | string |                                                                                                                      |
| key_name              | The EC2 Key Pair name to allow SSH access to the instances                                                 | string |                                                                                                                      |
| enable_volume_encryption | Encrypt Environment instances volume with default AWS KMS key                                              | bool   | true/false<br>**Default:** true                                                                                        |
| enable_instance_connect  | Enable SSH connection over AWS web console. Supporting regions can be found [here](https://aws.amazon.com/about-aws/whats-new/2019/06/introducing-amazon-ec2-instance-connect/) | bool   | true/false<br>**Default:** false                                                                                       |
| disable_instance_termination | Prevents an instance from accidental termination. Note: Once this attribute is true terraform destroy won't work properly | bool   | true/false<br>**Default:** false                                                                                       |
| metadata_imdsv2_required  | Set true to deploy the instance with metadata v2 token required                                          | bool   | true/false<br>**Default:** true                                                                                        |
| volume_size           | Instances volume size                                                                                     | number | **Default:** 200                                                                                                |
| allow_upload_download | Automatically download Blade Contracts and other important data. Improve product experience by sending data to Check Point | bool   | true/false<br>**Default:** true                                                                                        |
| management_server     | The name that represents the Security Management Server in the automatic provisioning configuration         | string | **Default:** CP-Management-gwlb-tf                                                                              |
| configuration_template | The tag is used by the Security Management Server to automatically provision the Security Gateways. Must be up to 12 alphanumeric characters and unique for each Quick Start deployment | string | **Default:** gwlb-configuration                                                                                |
| admin_shell           | Set the admin shell to enable advanced command line configuration                                          | string | - /etc/cli.sh<br>- /bin/bash<br>- /bin/csh<br>- /bin/tcsh<br>**Default:** /etc/cli.sh                                   |
| gateway_load_balancer_name | Load Balancer name in AWS                                                                               | string | **Default:** gwlb1                                                                                              |
| target_group_name     | Target Group Name. This name must be unique within your AWS account and can have a maximum of 32 alphanumeric characters and hyphens | string | **Default:** tg1                                                                                                |
| connection_acceptance_required | Indicate whether requests from service consumers to create an endpoint to your service must be accepted. Default is set to false (acceptance not required). | bool   | true/false<br>**Default:** false                                                                                       |
| enable_cross_zone_load_balancing | Select 'true' to enable cross-az load balancing. NOTE! this may cause a spike in cross-az charges. | bool   | true/false<br>**Default:** true                                                                                        |
| gateway_name          | The name tag of the Security Gateway instances. (optional)                                                | string | **Default:** Check-Point-GW-tf                                                                                  |
| gateway_instance_type | The instance type of the Security Gateways                                                                 | string | - c4.large <br/> - c4.xlarge <br/> - c5.large <br/> - c5.xlarge <br/> - c5.2xlarge <br/> - c5.4xlarge <br/> - c5.9xlarge <br/> - c5.12xlarge <br/> - c5.18xlarge <br/> - c5.24xlarge <br/> - c5n.large <br/> - c5n.xlarge <br/> - c5n.2xlarge <br/> - c5n.4xlarge <br/> - c5n.9xlarge <br/>  - c5n.18xlarge <br/>  - c5d.large <br/> - c5d.xlarge <br/> - c5d.2xlarge <br/> - c5d.4xlarge <br/> - c5d.9xlarge <br/> - c5d.12xlarge <br/>  - c5d.18xlarge <br/>  - c5d.24xlarge <br/> - m5.large <br/> - m5.xlarge <br/> - m5.2xlarge <br/> - m5.4xlarge <br/> - m5.8xlarge <br/> - m5.12xlarge <br/> - m5.16xlarge <br/> - m5.24xlarge <br/> - m6i.large <br/> - m6i.xlarge <br/> - m6i.2xlarge <br/> - m6i.4xlarge <br/> - m6i.8xlarge <br/> - m6i.12xlarge <br/> - m6i.16xlarge <br/> - m6i.24xlarge <br/> - m6i.32xlarge <br/> - c6i.large <br/> - c6i.xlarge <br/> - c6i.2xlarge <br/> - c6i.4xlarge <br/> - c6i.8xlarge <br/> - c6i.12xlarge <br/> - c6i.16xlarge <br/> - c6i.24xlarge <br/> - c6i.32xlarge <br/> - c6in.large <br/> - c6in.xlarge <br/> - c6in.2xlarge <br/> - c6in.4xlarge <br/> - c6in.8xlarge <br/> - c6in.12xlarge <br/> - c6in.16xlarge <br/> - c6in.24xlarge <br/> - c6in.32xlarge <br/> - r5.large <br/> - r5.xlarge <br/> - r5.2xlarge <br/> - r5.4xlarge <br/> - r5.8xlarge <br/> - r5.12xlarge <br/> - r5.16xlarge <br/> - r5.24xlarge <br/> - r5a.large <br/> - r5a.xlarge <br/> - r5a.2xlarge <br/> - r5a.4xlarge <br/> - r5a.8xlarge <br/> - r5a.12xlarge <br/> - r5a.16xlarge <br/> - r5a.24xlarge <br/> - r5b.large <br/> - r5b.xlarge <br/> - r5b.2xlarge <br/> - r5b.4xlarge <br/> - r5b.8xlarge <br/> - r5b.12xlarge <br/> - r5b.16xlarge <br/> - r5b.24xlarge <br/> - r5n.large <br/> - r5n.xlarge <br/> - r5n.2xlarge <br/> - r5n.4xlarge <br/> - r5n.8xlarge <br/> - r5n.12xlarge <br/> - r5n.16xlarge <br/> - r5n.24xlarge <br/> - r6i.large <br/> - r6i.xlarge <br/> - r6i.2xlarge <br/> - r6i.4xlarge <br/> - r6i.8xlarge <br/> - r6i.12xlarge <br/> - r6i.16xlarge <br/> - r6i.24xlarge <br/> - r6i.32xlarge <br/> - m6a.large <br/> - m6a.xlarge <br/> - m6a.2xlarge  <br/> - m6a.4xlarge <br/> - m6a.8xlarge <br/> - m6a.12xlarge <br/> - m6a.16xlarge <br/> - m6a.24xlarge <br/> - m6a.32xlarge <br/> - m6a.48xlarge <br/>**Default:** c5.xlarge                                                                                  |
| gateways_min_group_size | The minimal number of Security Gateways                                                                  | number | **Default:** 2                                                                                                  |
| gateways_max_group_size | The maximal number of Security Gateways                                                                  | number | **Default:** 10                                                                                                 |
| gateway_version                        | Gateway version and license                                                                                                                                                                                                      | string | - R81.20-BYOL<br>- R81.20-PAYG-NGTP<br>- R81.20-PAYG-NGTX<br>- R82-BYOL<br>- R82-PAYG-NGTP<br>- R82-PAYG-NGTX<br>**Default:** R81.20-BYOL          |
| gateway_password_hash                  | (Optional) Admin user's password hash (use command 'openssl passwd -6 PASSWORD' to get the PASSWORD's hash)                                                                                                                       | string |                                                                                                      |
| gateway_SICKey                         | The Secure Internal Communication key for trusted connection between Check Point components. Choose a random string consisting of at least 8 alphanumeric characters                                                             | string |                                                                             |
| enable_cloudwatch                      | Report Check Point specific CloudWatch metrics                                                                                                                                                                                  | bool   | true/false<br>**Default:** false                                                                        |
| gateway_bootstrap_script               | (Optional) An optional script with semicolon (;) separated commands to run on the initial boot                                                                                                                                  | string |                                                                                                      |
| gateways_provision_address_type        | Determines if the gateways are provisioned using their private or public address.                                                                                                                                               | string | - private<br>- public<br>**Default:** private                                                          |
| allocate_public_IP                     | Allocate a Public IP for gateway members.                                                                                                                                                                                       | bool   | true/false<br>**Default:** false                                                                        |
| management_deploy                      | Select 'false' to use an existing Security Management Server or to deploy one later and to ignore the other parameters of this section                                                                                           | bool   | true/false<br>**Default:** true                                                                         |
| management_instance_type               | The EC2 instance type of the Security Management Server                                                                                                                                                                         | string | - c4.large <br/> - c4.xlarge <br/> - c5.large <br/> - c5.xlarge <br/> - c5.2xlarge <br/> - c5.4xlarge <br/> - c5.9xlarge <br/> - c5.12xlarge <br/> - c5.18xlarge <br/> - c5.24xlarge <br/> - c5n.large <br/> - c5n.xlarge <br/> - c5n.2xlarge <br/> - c5n.4xlarge <br/> - c5n.9xlarge <br/>  - c5n.18xlarge <br/>  - c5d.large <br/> - c5d.xlarge <br/> - c5d.2xlarge <br/> - c5d.4xlarge <br/> - c5d.9xlarge <br/> - c5d.12xlarge <br/>  - c5d.18xlarge <br/>  - c5d.24xlarge <br/> - m5.large <br/> - m5.xlarge <br/> - m5.2xlarge <br/> - m5.4xlarge <br/> - m5.8xlarge <br/> - m5.12xlarge <br/> - m5.16xlarge <br/> - m5.24xlarge <br/> - m6i.large <br/> - m6i.xlarge <br/> - m6i.2xlarge <br/> - m6i.4xlarge <br/> - m6i.8xlarge <br/> - m6i.12xlarge <br/> - m6i.16xlarge <br/> - m6i.24xlarge <br/> - m6i.32xlarge <br/> - c6i.large <br/> - c6i.xlarge <br/> - c6i.2xlarge <br/> - c6i.4xlarge <br/> - c6i.8xlarge <br/> - c6i.12xlarge <br/> - c6i.16xlarge <br/> - c6i.24xlarge <br/> - c6i.32xlarge <br/> - c6in.large <br/> - c6in.xlarge <br/> - c6in.2xlarge <br/> - c6in.4xlarge <br/> - c6in.8xlarge <br/> - c6in.12xlarge <br/> - c6in.16xlarge <br/> - c6in.24xlarge <br/> - c6in.32xlarge <br/> - r5.large <br/> - r5.xlarge <br/> - r5.2xlarge <br/> - r5.4xlarge <br/> - r5.8xlarge <br/> - r5.12xlarge <br/> - r5.16xlarge <br/> - r5.24xlarge <br/> - r5a.large <br/> - r5a.xlarge <br/> - r5a.2xlarge <br/> - r5a.4xlarge <br/> - r5a.8xlarge <br/> - r5a.12xlarge <br/> - r5a.16xlarge <br/> - r5a.24xlarge <br/> - r5b.large <br/> - r5b.xlarge <br/> - r5b.2xlarge <br/> - r5b.4xlarge <br/> - r5b.8xlarge <br/> - r5b.12xlarge <br/> - r5b.16xlarge <br/> - r5b.24xlarge <br/> - r5n.large <br/> - r5n.xlarge <br/> - r5n.2xlarge <br/> - r5n.4xlarge <br/> - r5n.8xlarge <br/> - r5n.12xlarge <br/> - r5n.16xlarge <br/> - r5n.24xlarge <br/> - r6i.large <br/> - r6i.xlarge <br/> - r6i.2xlarge <br/> - r6i.4xlarge <br/> - r6i.8xlarge <br/> - r6i.12xlarge <br/> - r6i.16xlarge <br/> - r6i.24xlarge <br/> - r6i.32xlarge <br/> - m6a.large <br/> - m6a.xlarge <br/> - m6a.2xlarge  <br/> - m6a.4xlarge <br/> - m6a.8xlarge <br/> - m6a.12xlarge <br/> - m6a.16xlarge <br/> - m6a.24xlarge <br/> - m6a.32xlarge <br/> - m6a.48xlarge <br/>**Default:** m5.xlarge                           |
| management_version                     | The license to install on the Security Management Server                                                                                                                                                                        | string | - R81.10-BYOL<br>- R81.10-PAYG<br>- R81.20-BYOL<br>- R81.20-PAYG<br>**Default:** R81.20-BYOL                                                 |
| management_password_hash               | (Optional) Admin user's password hash (use command 'openssl passwd -6 PASSWORD' to get the PASSWORD's hash)                                                                                                                     | string |                                                                                                      |
| gateways_policy                        | The name of the Security Policy package to be installed on the gateways in the Security Gateways Auto Scaling group                                                                                                             | string | **Default:** Standard                                                                           |
| gateway_management                     | Select 'Over the internet' if any of the gateways you wish to manage are not directly accessed via their private IP address.                                                                                                     | string | - Locally managed<br>- Over the internet<br>**Default:** Locally managed                               |
| admin_cidr                             | (CIDR) Allow web, ssh, and graphical clients only from this network to communicate with the Management Server                                                                                                                    | string | valid CIDR                                                                                            |
| gateway_addresses                      | (CIDR) Allow gateways only from this network to communicate with the Management Server                                                                                                                                          | string | valid CIDR                                                                                            |
| volume_type                            | General Purpose SSD Volume Type                                                                                                                                                                                                | string | - gp3<br>- gp2<br>**Default:** gp3                                                                     |
| gateway_maintenance_mode_password_hash | Check Point recommends setting Admin user's password and maintenance-mode password for recovery purposes. For R81.10 and below the Admin user's password is used also as maintenance-mode password. (To generate a password hash use the command "grub2-mkpasswd-pbkdf2" on Linux and paste it here). | string |                                                                                                      |
| management_maintenance_mode_password_hash | Check Point recommends setting Admin user's password and maintenance-mode password for recovery purposes. For R81.10 and below the Admin user's password is used also as maintenance-mode password. (To generate a password hash use the command "grub2-mkpasswd-pbkdf2" on Linux and paste it here). | string |                                                                                                      |
| enable_ipv6                               | Enables dual-stack networking (IPv4 and IPv6) for the GWLB, [Please see version compatibility in the following guide](https://sc1.checkpoint.com/documents/IaaS/WebAdminGuides/EN/CP_CloudGuard_Network_for_AWS_Gateway_Load_Balancer_ASG/Content/Topics-AWS-GWLB-ASG-DG/IPv6-Support.htm) | bool   | true/false<br>**Default:** false                                         |

## Outputs
To display the outputs defined by the module, create an `outputs.tf` file with the following structure:
```
output "instance_public_ip" {
  value = module.{module_name}.instance_public_ip
}
```
| Name                | Description                                                                           |
|---------------------|---------------------------------------------------------------------------------------|
| managment_public_ip | The deployed Security Management AWS instance public IP                               |
| load_balancer_url   | The URL of the external Load Balancer                                                 |
| template_name       | Name of a gateway configuration template in the automatic provisioning configuration. |
| controller_name     | The controller name in CME.                                                           |
| gwlb_name           | The name of the deployed Gateway Load Balancer                                        |
| gwlb_service_name   | The service name for the deployed Gateway Load Balancer                               |
| gwlb_arn            | The arn for the deployed Gateway Load Balancer                                        |
| enable_ipv6         | Dual-stack IPv4/IPv6 compatible                                                       |

