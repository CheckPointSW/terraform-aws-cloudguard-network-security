# Check Point CloudGuard Network Auto Scaling GWLB Terraform module for AWS

Terraform module which deploys an Auto Scaling Group of Check Point Security Gateways into an existing VPC.

These types of Terraform resources are supported:
* [Launch template](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_template)
* [Auto Scaling Group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group)
* [Security group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group)
* [CloudWatch Metric Alarm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm)


See the [CloudGuard Auto Scaling for AWS](https://sc1.checkpoint.com/documents/IaaS/WebAdminGuides/EN/CloudGuard_Network_for_AWS_AutoScaling_DeploymentGuide/Topics-AWS-AutoScale-DG/Check-Point-CloudGuard-Network-for-AWS.htm) for additional information

This solution uses the following modules:
- amis


## Usage
Follow best practices for using CGNS modules on [the root page](https://registry.terraform.io/modules/checkpointsw/cloudguard-network-security/aws/latest#:~:text=Best%20Practices%20for%20Using%20Our%20Modules).

## Inputs
| Name                                   | Description                                                                                                                                                                      | Type       | Allowed Values                                                                                                    |
|----------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|------------|------------------------------------------------------------------------------------------------------------------|
| prefix                                 | (Optional) Instances name prefix                                                                                                                                                 | string     |                                                                                                               |
| asg_name                               | Autoscaling Group name                                                                                                                                                           | string     |                                                                                                               |
| vpc_id                                 | The VPC id in which to deploy                                                                                                                                                    | string     |                                                                                                               |
| subnet_ids                             | List of public subnet IDs to launch resources into. Recommended at least 2                                                                                                       | list(string)|                                                                                                               |
| gateways_provision_address_type        | Determines if the gateways are provisioned using their private or public address.                                                                                                | string     | - private<br>- public<br>**Default:** private                                                                   |
| allocate_public_IP                     | Allocate a Public IP for gateway members.                                                                                                                                        | bool       | true/false<br>**Default:** false                                                                                |
| management_server                      | The name that represents the Security Management Server in the CME configuration                                                                                                 | string     |                                                                                                               |
| configuration_template                 | Name of the provisioning template in the CME configuration                                                                                                                       | string     |                                                                                                               |
| gateway_name                           | The name tag of the Security Gateways instances                                                                                                                                  | string     | <br>**Default:** Check-Point-ASG-gateway-tf                                                                  |
| gateway_instance_type                  | The instance type of the Security Gateways                                                                                                                                        | string     | - c5.large<br>- c5.xlarge<br>- m6a.large<br>- c6i.xlarge<br>**Default:** c5.xlarge                              |
| key_name                               | The EC2 Key Pair name to allow SSH access to the instances                                                                                                                        | string     |                                                                                                               |
| volume_size                            | Root volume size (GB) - minimum 100                                                                                                                                               | number     | <br>**Default:** 100                                                                                        |
| enable_volume_encryption               | Encrypt Environment instances volume with default AWS KMS key                                                                                                                     | bool       | true/false<br>**Default:** true                                                                                 |
| instances_tags                         | (Optional) A map of tags as key=value pairs. All tags will be added on all AutoScaling Group instances                                                                             | map(string)| <br>**Default:** {}                                                                                          |
| metadata_imdsv2_required               | Set true to deploy the instance with metadata v2 token required                                                                                                                   | bool       | true/false<br>**Default:** true                                                                                 |
| minimum_group_size                     | The minimum number of instances in the Auto Scaling group                                                                                                                         | number     | <br>**Default:** 2                                                                                          |
| maximum_group_size                     | The maximum number of instances in the Auto Scaling group                                                                                                                         | number     | <br>**Default:** 10                                                                                         |
| target_groups                          | (Optional) List of Target Group ARNs to associate with the Auto Scaling group                                                                                                     | list(string)|                                                                                                               |
| gateway_version                        | Gateway version and license                                                                                                                                                       | string     | - R81.20-BYOL<br>- R81.20-PAYG-NGTP<br>- R82-BYOL<br>**Default:** R81.20-BYOL                                   |
| admin_shell                            | Set the admin shell to enable advanced command line configuration                                                                                                                 | string     | - /etc/cli.sh<br>- /bin/bash<br>- /bin/csh<br>**Default:** /etc/cli.sh                                          |
| gateway_password_hash                  | (Optional) Check Point recommends setting Admin user's password and maintenance-mode password for recovery purposes.                                                              | string     |                                                                                                               |
| gateway_SICKey                         | The Secure Internal Communication key for trusted connection between Check Point components (at least 8 alphanumeric characters)                                                   | string     | <br>**Default:** "12345678"                                                                                  |
| enable_instance_connect                | Enable SSH connection over AWS web console. Supporting regions can be found [here](https://aws.amazon.com/about-aws/whats-new/2019/06/introducing-amazon-ec2-instance-connect/)   | bool       | true/false<br>**Default:** false                                                                                |
| allow_upload_download                  | Automatically download Blade Contracts and other important data. Improve product experience by sending data to Check Point                                                         | bool       | true/false<br>**Default:** true                                                                                 |
| enable_cloudwatch                      | Report Check Point specific CloudWatch metrics                                                                                                                                   | bool       | true/false<br>**Default:** false                                                                                |
| gateway_bootstrap_script               | (Optional) Semicolon (;) separated commands to run on the initial boot                                                                                                            | string     |                                                                                                               |
| volume_type                            | General Purpose SSD Volume Type                                                                                                                                                  | string     | - gp3<br>- gp2<br>**Default:** gp3                                                                             |
| gateway_maintenance_mode_password_hash | (Optional) Maintenance-mode password for recovery purposes.                                                                                                                       | string     |                                                                                                               |


## Outputs
| Name                                           | Description                                                       |
|------------------------------------------------|-------------------------------------------------------------------|
| autoscale_autoscaling_group_name               | The name of the deployed AutoScaling Group                        |
| autoscale_autoscaling_group_arn                | The ARN for the deployed AutoScaling Group                        |
| autoscale_autoscaling_group_availability_zones | The AZs on which the Autoscaling Group is configured              |
| autoscale_autoscaling_group_desired_capacity   | The deployed AutoScaling Group's desired capacity of instances    |
| autoscale_autoscaling_group_min_size           | The deployed AutoScaling Group's minimum number of instances      |
| autoscale_autoscaling_group_max_size           | The deployed AutoScaling Group's maximum number  of instances     |
| autoscale_autoscaling_group_target_group_arns  | The deployed AutoScaling Group's configured target groups         |
| autoscale_autoscaling_group_subnets            | The subnets on which the deployed AutoScaling Group is configured |
| autoscale_launch_template_id                   | The id of the Launch Template                                     |
| autoscale_autoscale_security_group_id          | The deployed AutoScaling Group's security group id                |
| autoscale_iam_role_name                        | The deployed AutoScaling Group's IAM role name (if created)       |
