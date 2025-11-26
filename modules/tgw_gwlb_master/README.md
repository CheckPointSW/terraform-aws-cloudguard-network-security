# Check Point CloudGuard Network Gateway Load Balancer for Transit Gateway Terraform Master module for AWS

Terraform module which deploys an AWS Auto Scaling group configured for Gateway Load Balancer into new Centralized Security VPC for Transit Gateway.

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
- vpc
- management
- cme_iam_role_gwlb
- amis
- gwlb

## Usage
Follow best practices for using CGNS modules on [the root page](https://registry.terraform.io/modules/checkpointsw/cloudguard-network-security/aws/latest#:~:text=Best%20Practices%20for%20Using%20Our%20Modules).


**Example:**
```
provider "aws" {}

module "example_module" {

    source  = "CheckPointSW/cloudguard-network-security/aws//modules/tgw_gwlb_master"
    version = "1.0.4"

    // --- VPC Network Configuration --
    vpc_cidr = "10.0.0.0/16"
    public_subnets_map = {
     "us-east-1a" = 1
     "us-east-1b" = 2
     "us-east-1c" = 3
     "us-east-1d" = 4
    }
    tgw_subnets_map = {
     "us-east-1a" = 5
     "us-east-1b" = 6
     "us-east-1c" = 7
     "us-east-1d" = 8
    }
    subnets_bit_length = 8
      
    availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c", "us-east-1d"]
    number_of_AZs = 4
        
    nat_gw_subnet_1_cidr ="10.0.13.0/24"
    nat_gw_subnet_2_cidr = "10.0.23.0/24"
    nat_gw_subnet_3_cidr = "10.0.33.0/24"
    nat_gw_subnet_4_cidr = "10.0.43.0/24"
        
    gwlbe_subnet_1_cidr = "10.0.14.0/24"
    gwlbe_subnet_2_cidr = "10.0.24.0/24"
    gwlbe_subnet_3_cidr = "10.0.34.0/24"
    gwlbe_subnet_4_cidr = "10.0.44.0/24" 
        
    // --- General Settings ---
    key_name = "publickey"
    enable_volume_encryption = true
    volume_size = 100
    enable_instance_connect = false
    disable_instance_termination = false
    allow_upload_download = true
    management_server = "CP-Management-gwlb-tf"
    configuration_template = "gwlb-configuration"
    admin_shell = "/etc/cli.sh"
        
    // --- Gateway Load Balancer Configuration ---
    gateway_load_balancer_name = "gwlb1"
    target_group_name = "tg1"
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
    admin_cidr = "0.0.0.0/0"
    gateways_addresses = "0.0.0.0/0"
        
    // --- Other parameters ---
    volume_type = "gp3"
```

- Conditional creation
  - To enable cloudwatch for tgw_gwlb_master:
```
  enable_cloudwatch = true
```
  Note: enabling cloudwatch will automatically create IAM role with cloudwatch:PutMetricData permission
  - To deploy Security Management Server:
```
  management_deploy = true
```


## Inputs

| Name                                      | Description                                                                                                                                                                      | Type         | Allowed Values                                                                                                                                                                 |
|-------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|--------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| vpc_cidr                                  | The CIDR block of the VPC                                                                                                                                                        | string       |                                                                                                                                                                          |
| subnets_bit_length                        | Number of additional bits to extend the VPC CIDR. For example, a /16 CIDR with a subnets_bit_length of 4 results in /20 subnets.                                                 | number       |                                                                                                                                                                          |
| public_subnets_map                        | A map of {availability-zone = subnet-suffix-number}. Minimum 1 pair (e.g., {"us-east-1a" = 1}).                                                                                  | map          |                                                                                                                                                                          |
| availability_zones                        | The Availability Zones (AZs) to use for the subnets in the VPC.                                                                                                                  | string       |                                                                                                                                                                          |
| Number_of_AZs                             | Number of Availability Zones to use in the VPC.                                                                                                                                  | number       | **Default:** 2                                                                                                                                                      |
| tgw_subnets_map                           | A map of {availability-zone = subnet-suffix-number} for TGW subnets. Minimum 2 pairs (e.g., {"us-east-1a" = 1}).                                                                | map          |                                                                                                                                                                          |
| nat_gw_subnet_1_cidr                      | CIDR block for NAT subnet 1 in the 1st Availability Zone                                                                                                                         | string       | **Default:** 10.0.13.0/24                                                                                                                                           |
| nat_gw_subnet_2_cidr                      | CIDR block for NAT subnet 2 in the 2nd Availability Zone                                                                                                                         | string       | **Default:** 10.0.23.0/24                                                                                                                                           |
| nat_gw_subnet_3_cidr                      | CIDR block for NAT subnet 3 in the 3rd Availability Zone                                                                                                                         | string       | **Default:** 10.0.33.0/24                                                                                                                                           |
| nat_gw_subnet_4_cidr                      | CIDR block for NAT subnet 4 in the 4th Availability Zone                                                                                                                         | string       | **Default:** 10.0.43.0/24                                                                                                                                           |
| gwlbe_subnet_1_cidr                       | CIDR block for GWLBe subnet 1 in the 1st Availability Zone                                                                                                                       | string       | **Default:** 10.0.14.0/24                                                                                                                                           |
| gwlbe_subnet_2_cidr                       | CIDR block for GWLBe subnet 2 in the 2nd Availability Zone                                                                                                                       | string       | **Default:** 10.0.24.0/24                                                                                                                                           |
| gwlbe_subnet_3_cidr                       | CIDR block for GWLBe subnet 3 in the 3rd Availability Zone                                                                                                                       | string       | **Default:** 10.0.34.0/24                                                                                                                                           |
| gwlbe_subnet_4_cidr                       | CIDR block for GWLBe subnet 4 in the 4th Availability Zone                                                                                                                       | string       | **Default:** 10.0.44.0/24                                                                                                                                           |
| key_name                                  | The EC2 Key Pair name to allow SSH access to the instances                                                                                                                        | string       |                                                                                                                                                                          |
| enable_volume_encryption                  | Encrypt Environment instances volume with default AWS KMS key                                                                                                                     | bool         | true/false<br>**Default:** true                                                                                                                                           |
| enable_instance_connect                   | Enable SSH connection over AWS web console. Supporting regions can be found [here](https://aws.amazon.com/about-aws/whats-new/2019/06/introducing-amazon-ec2-instance-connect/)   | bool         | true/false<br>**Default:** false                                                                                                                                          |
| disable_instance_termination              | Prevents accidental termination. Note: When true, `terraform destroy` won’t work properly.                                                                                        | bool         | true/false<br>**Default:** false                                                                                                                                          |
| metadata_imdsv2_required                  | Set true to deploy instances with IMDSv2 metadata token required.                                                                                                                | bool         | true/false<br>**Default:** true                                                                                                                                           |
| volume_size                               | Instance volume size                                                                                                                                                             | number       | **Default:** 100                                                                                                                                                   |
| allow_upload_download                     | Automatically download Blade Contracts and other data.                                                                                                                            | bool         | true/false<br>**Default:** true                                                                                                                                           |
| management_server                         | The name representing the Security Management Server in the automatic provisioning configuration.                                                                                 | string       | **Default:** CP-Management-gwlb-tf                                                                                                                                |
| configuration_template                    | The provisioning tag for the Security Gateways. Must be up to 12 alphanumeric characters and unique.                                                                              | string       | **Default:** gwlb-ter                                                                                                                                              |
| admin_shell                               | Set the admin shell for advanced command line configuration.                                                                                                                      | string       | - /etc/cli.sh<br>- /bin/bash<br>- /bin/csh<br>- /bin/tcsh<br>**Default:** /etc/cli.sh                                                                                     |
| gateway_load_balancer_name                | Load Balancer name in AWS                                                                                                                                                         | string       | **Default:** gwlb-terraform                                                                                                                                       |
| target_group_name                         | Target Group Name. Must be unique within your AWS account with up to 32 alphanumeric characters and hyphens.                                                                     | string       | **Default:** tg1-terraform                                                                                                                                        |
| connection_acceptance_required            | Indicate whether service consumers must accept endpoint requests. Default is false (not required).                                                                                | bool         | true/false<br>**Default:** false                                                                                                                                          |
| enable_cross_zone_load_balancing          | Enable cross-AZ load balancing. This may increase cross-AZ charges.                                                                                                               | bool         | true/false<br>**Default:** true                                                                                                                                           |
| gateway_name                              | The name tag of the Security Gateway instances.                                                                                                                                   | string       | **Default:** gwlb-terraform                                                                                                                                       |
| gateway_instance_type                     | The instance type of the Security Gateways                                                                                                                                       | string       | - c4.large <br/> - c4.xlarge <br/> - c5.large <br/> - c5.xlarge <br/> - c5.2xlarge <br/> - c5.4xlarge <br/> - c5.9xlarge <br/> - c5.12xlarge <br/> - c5.18xlarge <br/> - c5.24xlarge <br/> - c5n.large <br/> - c5n.xlarge <br/> - c5n.2xlarge <br/> - c5n.4xlarge <br/> - c5n.9xlarge <br/>  - c5n.18xlarge <br/>  - c5d.large <br/> - c5d.xlarge <br/> - c5d.2xlarge <br/> - c5d.4xlarge <br/> - c5d.9xlarge <br/> - c5d.12xlarge <br/>  - c5d.18xlarge <br/>  - c5d.24xlarge <br/> - m5.large <br/> - m5.xlarge <br/> - m5.2xlarge <br/> - m5.4xlarge <br/> - m5.8xlarge <br/> - m5.12xlarge <br/> - m5.16xlarge <br/> - m5.24xlarge <br/> - m6i.large <br/> - m6i.xlarge <br/> - m6i.2xlarge <br/> - m6i.4xlarge <br/> - m6i.8xlarge <br/> - m6i.12xlarge <br/> - m6i.16xlarge <br/> - m6i.24xlarge <br/> - m6i.32xlarge <br/> - c6i.large <br/> - c6i.xlarge <br/> - c6i.2xlarge <br/> - c6i.4xlarge <br/> - c6i.8xlarge <br/> - c6i.12xlarge <br/> - c6i.16xlarge <br/> - c6i.24xlarge <br/> - c6i.32xlarge <br/> - c6in.large <br/> - c6in.xlarge <br/> - c6in.2xlarge <br/> - c6in.4xlarge <br/> - c6in.8xlarge <br/> - c6in.12xlarge <br/> - c6in.16xlarge <br/> - c6in.24xlarge <br/> - c6in.32xlarge <br/> - r5.large <br/> - r5.xlarge <br/> - r5.2xlarge <br/> - r5.4xlarge <br/> - r5.8xlarge <br/> - r5.12xlarge <br/> - r5.16xlarge <br/> - r5.24xlarge <br/> - r5a.large <br/> - r5a.xlarge <br/> - r5a.2xlarge <br/> - r5a.4xlarge <br/> - r5a.8xlarge <br/> - r5a.12xlarge <br/> - r5a.16xlarge <br/> - r5a.24xlarge <br/> - r5b.large <br/> - r5b.xlarge <br/> - r5b.2xlarge <br/> - r5b.4xlarge <br/> - r5b.8xlarge <br/> - r5b.12xlarge <br/> - r5b.16xlarge <br/> - r5b.24xlarge <br/> - r5n.large <br/> - r5n.xlarge <br/> - r5n.2xlarge <br/> - r5n.4xlarge <br/> - r5n.8xlarge <br/> - r5n.12xlarge <br/> - r5n.16xlarge <br/> - r5n.24xlarge <br/> - r6i.large <br/> - r6i.xlarge <br/> - r6i.2xlarge <br/> - r6i.4xlarge <br/> - r6i.8xlarge <br/> - r6i.12xlarge <br/> - r6i.16xlarge <br/> - r6i.24xlarge <br/> - r6i.32xlarge <br/> - m6a.large <br/> - m6a.xlarge <br/> - m6a.2xlarge  <br/> - m6a.4xlarge <br/> - m6a.8xlarge <br/> - m6a.12xlarge <br/> - m6a.16xlarge <br/> - m6a.24xlarge <br/> - m6a.32xlarge <br/> - m6a.48xlarge <br/> **Default:** c5.xlarge                                                                                                       |
| gateways_min_group_size                   | The minimum number of Security Gateways                                                                                                                                           | number       | **Default:** 2                                                                                                                                                     |
| gateways_max_group_size                   | The maximum number of Security Gateways                                                                                                                                           | number       | **Default:** 10                                                                                                                                                    |
| gateway_version                           | Gateway version and license                                                                                                                                                      | string       | - R81.20-BYOL<br>- R81.20-PAYG-NGTP<br>- R81.20-PAYG-NGTX<br>- R82-BYOL<br>- R82-PAYG-NGTP<br>- R82-PAYG-NGTX<br>**Default:** R81.20-BYOL                                                                        |
| gateway_password_hash                     | (Optional) Admin user's password hash (use command `openssl passwd -6 PASSWORD` to get the PASSWORD's hash).                                                                      | string       |                                                                                                                                                                          |
| gateway_SICKey                            | The Secure Internal Communication key for trusted connections between Check Point components. At least 8 alphanumeric characters.                                                 | string       | **Default:** "12345678"                                                                                                                                           |
| enable_cloudwatch                         | Report Check Point-specific CloudWatch metrics.                                                                                                                                   | bool         | true/false<br>**Default:** false                                                                                                                                          |
| gateway_bootstrap_script                  | (Optional) Semicolon-separated commands to run on initial boot.                                                                                                                   | string       |                                                                                                                                                                          |
| gateways_provision_address_type           | Determines if gateways are provisioned using private or public addresses.                                                                                                         | string       | - private<br>- public<br>**Default:** private                                                                                                                            |
| allocate_public_IP                        | Allocate a Public IP for gateway members.                                                                                                                                        | bool         | true/false<br>**Default:** false                                                                                                                                          |
| management_deploy                         | Use an existing Security Management Server or deploy a new one.                                                                                                                  | bool         | true/false<br>**Default:** true                                                                                                                                           |
| management_instance_type                  | The EC2 instance type of the Security Management Server                                                                                                                          | string       | - c5.large <br/> - c5.xlarge <br/> - c5.2xlarge <br/> - c5.4xlarge <br/> - c5.9xlarge <br/> - c5.12xlarge <br/> - c5.18xlarge <br/> - c5.24xlarge <br/> - c5n.large <br/> - c5n.xlarge <br/> - c5n.2xlarge <br/> - c5n.4xlarge <br/> - c5n.9xlarge <br/>  - c5n.18xlarge <br/>  - c5d.large <br/> - c5d.xlarge <br/> - c5d.2xlarge <br/> - c5d.4xlarge <br/> - c5d.9xlarge <br/> - c5d.12xlarge <br/>  - c5d.18xlarge <br/>  - c5d.24xlarge <br/> - m5.large <br/> - m5.xlarge <br/> - m5.2xlarge <br/> - m5.4xlarge <br/> - m5.8xlarge <br/> - m5.12xlarge <br/> - m5.16xlarge <br/> - m5.24xlarge <br/> - m6i.large <br/> - m6i.xlarge <br/> - m6i.2xlarge <br/> - m6i.4xlarge <br/> - m6i.8xlarge <br/> - m6i.12xlarge <br/> - m6i.16xlarge <br/> - m6i.24xlarge <br/> - m6i.32xlarge <br/> - c6i.large <br/> - c6i.xlarge <br/> - c6i.2xlarge <br/> - c6i.4xlarge <br/> - c6i.8xlarge <br/> - c6i.12xlarge <br/> - c6i.16xlarge <br/> - c6i.24xlarge <br/> - c6i.32xlarge <br/> - c6in.large <br/> - c6in.xlarge <br/> - c6in.2xlarge <br/> - c6in.4xlarge <br/> - c6in.8xlarge <br/> - c6in.12xlarge <br/> - c6in.16xlarge <br/> - c6in.24xlarge <br/> - c6in.32xlarge <br/> - r5.large <br/> - r5.xlarge <br/> - r5.2xlarge <br/> - r5.4xlarge <br/> - r5.8xlarge <br/> - r5.12xlarge <br/> - r5.16xlarge <br/> - r5.24xlarge <br/> - r5a.large <br/> - r5a.xlarge <br/> - r5a.2xlarge <br/> - r5a.4xlarge <br/> - r5a.8xlarge <br/> - r5a.12xlarge <br/> - r5a.16xlarge <br/> - r5a.24xlarge <br/> - r5b.large <br/> - r5b.xlarge <br/> - r5b.2xlarge <br/> - r5b.4xlarge <br/> - r5b.8xlarge <br/> - r5b.12xlarge <br/> - r5b.16xlarge <br/> - r5b.24xlarge <br/> - r5n.large <br/> - r5n.xlarge <br/> - r5n.2xlarge <br/> - r5n.4xlarge <br/> - r5n.8xlarge <br/> - r5n.12xlarge <br/> - r5n.16xlarge <br/> - r5n.24xlarge <br/> - r6i.large <br/> - r6i.xlarge <br/> - r6i.2xlarge <br/> - r6i.4xlarge <br/> - r6i.8xlarge <br/> - r6i.12xlarge <br/> - r6i.16xlarge <br/> - r6i.24xlarge <br/> - r6i.32xlarge <br/> - m6a.large <br/> - m6a.xlarge <br/> - m6a.2xlarge  <br/> - m6a.4xlarge <br/> - m6a.8xlarge <br/> - m6a.12xlarge <br/> - m6a.16xlarge <br/> - m6a.24xlarge <br/> - m6a.32xlarge <br/> - m6a.48xlarge <br/> **Default:** c5.xlarge                                                                                        |
| management_version                        | The license to install on the Security Management Server.                                                                                                                        | string       | - R81.10-BYOL<br>- R81.10-PAYG<br>- R81.20-BYOL<br>- R81.20-PAYG<br>**Default:** R81.20-BYOL                                                                              |
| management_password_hash                  | (Optional) Admin user's password hash (use command `openssl passwd -6 PASSWORD` to get the PASSWORD's hash).                                                                      | string       |                                                                                                                                                                          |
| gateways_policy                           | The name of the Security Policy package to install on gateways in the Auto Scaling group.                                                                                        | string       | **Default:** Standard                                                                                                                                             |
| gateway_management                        | Select 'Over the internet' if managing gateways not directly accessible via private IP addresses.                                                                                | string       | - Locally managed<br>- Over the internet<br>**Default:** Locally managed                                                                                                |
| admin_cidr                                | (CIDR) Allow web, ssh, and graphical clients from this network to communicate with the Management Server.                                                                         | string       | valid CIDR                                                                                                                                                                |
| gateway_addresses                         | (CIDR) Allow gateways from this network to communicate with the Management Server.                                                                                                | string       | valid CIDR                                                                                                                                                                |
| volume_type                               | General Purpose SSD Volume Type                                                                                                                                                  | string       | - gp3<br>- gp2<br>**Default:** gp3                                                                                                                                       |
| gateway_maintenance_mode_password_hash    | (Optional) Maintenance-mode password hash for recovery purposes.                                                                                                                  | string       |                                                                                                                                                                          |
| management_maintenance_mode_password_hash | (Optional) Maintenance-mode password hash for recovery purposes.                                                                                                                  | string       |                                                                                                                                                                          |


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
