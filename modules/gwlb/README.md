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
- To tear down your resources:
    ```
    terraform destroy
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
| volume_size           | Instances volume size                                                                                     | number | **Default:** 100                                                                                                |
| allow_upload_download | Automatically download Blade Contracts and other important data. Improve product experience by sending data to Check Point | bool   | true/false<br>**Default:** true                                                                                        |
| management_server     | The name that represents the Security Management Server in the automatic provisioning configuration         | string | **Default:** CP-Management-gwlb-tf                                                                              |
| configuration_template | The tag is used by the Security Management Server to automatically provision the Security Gateways. Must be up to 12 alphanumeric characters and unique for each Quick Start deployment | string | **Default:** gwlb-configuration                                                                                |
| admin_shell           | Set the admin shell to enable advanced command line configuration                                          | string | - /etc/cli.sh<br>- /bin/bash<br>- /bin/csh<br>- /bin/tcsh<br>**Default:** /etc/cli.sh                                   |
| gateway_load_balancer_name | Load Balancer name in AWS                                                                               | string | **Default:** gwlb1                                                                                              |
| target_group_name     | Target Group Name. This name must be unique within your AWS account and can have a maximum of 32 alphanumeric characters and hyphens | string | **Default:** tg1                                                                                                |
| connection_acceptance_required | Indicate whether requests from service consumers to create an endpoint to your service must be accepted. Default is set to false (acceptance not required). | bool   | true/false<br>**Default:** false                                                                                       |
| enable_cross_zone_load_balancing | Select 'true' to enable cross-az load balancing. NOTE! this may cause a spike in cross-az charges. | bool   | true/false<br>**Default:** true                                                                                        |
| gateway_name          | The name tag of the Security Gateway instances. (optional)                                                | string | **Default:** Check-Point-GW-tf                                                                                  |
| gateway_instance_type | The instance type of the Security Gateways                                                                 | string | - c5.xlarge<br>**Default:** c5.xlarge                                                                                  |
| gateways_min_group_size | The minimal number of Security Gateways                                                                  | number | **Default:** 2                                                                                                  |
| gateways_max_group_size | The maximal number of Security Gateways                                                                  | number | **Default:** 10                                                                                                 |
| gateway_version                        | Gateway version and license                                                                                                                                                                                                      | string | - R81.20-BYOL<br>- R81.20-PAYG-NGTP<br>- R81.20-PAYG-NGTX<br>- R82-BYOL<br>- R82-PAYG-NGTP<br>- R82-PAYG-NGTX<br>**Default:** R81.20-BYOL          |
| gateway_password_hash                  | (Optional) Admin user's password hash (use command 'openssl passwd -6 PASSWORD' to get the PASSWORD's hash)                                                                                                                       | string |                                                                                                      |
| gateway_SICKey                         | The Secure Internal Communication key for trusted connection between Check Point components. Choose a random string consisting of at least 8 alphanumeric characters                                                             | string | **Default:** 12345678                                                                            |
| enable_cloudwatch                      | Report Check Point specific CloudWatch metrics                                                                                                                                                                                  | bool   | true/false<br>**Default:** false                                                                        |
| gateway_bootstrap_script               | (Optional) An optional script with semicolon (;) separated commands to run on the initial boot                                                                                                                                  | string |                                                                                                      |
| gateways_provision_address_type        | Determines if the gateways are provisioned using their private or public address.                                                                                                                                               | string | - private<br>- public<br>**Default:** private                                                          |
| allocate_public_IP                     | Allocate a Public IP for gateway members.                                                                                                                                                                                       | bool   | true/false<br>**Default:** false                                                                        |
| management_deploy                      | Select 'false' to use an existing Security Management Server or to deploy one later and to ignore the other parameters of this section                                                                                           | bool   | true/false<br>**Default:** true                                                                         |
| management_instance_type               | The EC2 instance type of the Security Management Server                                                                                                                                                                         | string | - c5.large<br>- c5.xlarge<br>- c5.2xlarge<br>- c5.4xlarge<br>- c5.9xlarge<br>- m6a.48xlarge<br>**Default:** m5.xlarge                           |
| management_version                     | The license to install on the Security Management Server                                                                                                                                                                        | string | - R81.10-BYOL<br>- R81.10-PAYG<br>- R81.20-BYOL<br>- R81.20-PAYG<br>**Default:** R81.20-BYOL                                                 |
| management_password_hash               | (Optional) Admin user's password hash (use command 'openssl passwd -6 PASSWORD' to get the PASSWORD's hash)                                                                                                                     | string |                                                                                                      |
| gateways_policy                        | The name of the Security Policy package to be installed on the gateways in the Security Gateways Auto Scaling group                                                                                                             | string | **Default:** Standard                                                                           |
| gateway_management                     | Select 'Over the internet' if any of the gateways you wish to manage are not directly accessed via their private IP address.                                                                                                     | string | - Locally managed<br>- Over the internet<br>**Default:** Locally managed                               |
| admin_cidr                             | (CIDR) Allow web, ssh, and graphical clients only from this network to communicate with the Management Server                                                                                                                    | string | valid CIDR                                                                                            |
| gateway_addresses                      | (CIDR) Allow gateways only from this network to communicate with the Management Server                                                                                                                                          | string | valid CIDR                                                                                            |
| volume_type                            | General Purpose SSD Volume Type                                                                                                                                                                                                | string | - gp3<br>- gp2<br>**Default:** gp3                                                                     |
| gateway_maintenance_mode_password_hash | Check Point recommends setting Admin user's password and maintenance-mode password for recovery purposes. For R81.10 and below the Admin user's password is used also as maintenance-mode password. (To generate a password hash use the command "grub2-mkpasswd-pbkdf2" on Linux and paste it here). | string |                                                                                                      |
| management_maintenance_mode_password_hash | Check Point recommends setting Admin user's password and maintenance-mode password for recovery purposes. For R81.10 and below the Admin user's password is used also as maintenance-mode password. (To generate a password hash use the command "grub2-mkpasswd-pbkdf2" on Linux and paste it here). | string |                                                                                                      |

## Outputs
| Name                | Description                                                                           |
|---------------------|---------------------------------------------------------------------------------------|
| managment_public_ip | The deployed Security Management AWS instance public IP                               |
| load_balancer_url   | The URL of the external Load Balancer                                                 |
| template_name       | Name of a gateway configuration template in the automatic provisioning configuration. |
| controller_name     | The controller name in CME.                                                           |
| gwlb_name           | The name of the deployed Gateway Load Balancer                                        |
| gwlb_service_name   | The service name for the deployed Gateway Load Balancer                               |
| gwlb_arn            | The arn for the deployed Gateway Load Balancer                                        |


