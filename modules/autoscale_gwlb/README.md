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


**Example:**
```
provider "aws" {}

module "example_module" {

    source  = "CheckPointSW/cloudguard-network-security/aws//modules/autoscale_gwlb"
    version = "1.0.4"

        // --- Environment ---
    prefix = "env1"
    asg_name = "autoscaling_group"

    // --- VPC Network Configuration ---
    vpc_id = "vpc-12345678"
    subnet_ids = ["subnet-abc123", "subnet-def456"]

    // --- Automatic Provisioning with Security Management Server Settings ---
    gateways_provision_address_type = "private"
    allocate_public_IP = false
    management_server = "mgmt_env1"
    configuration_template = "tmpl_env1"

    // --- EC2 Instances Configuration ---
    gateway_name = "asg_gateway"
    gateway_instance_type = "c5.xlarge"
    key_name = "publickey"
    instances_tags = {
        key1 = "value1"
        key2 = "value2"
    }

    // --- Auto Scaling Configuration ---
    minimum_group_size = 2
    maximum_group_size = 10
    target_groups = ["arn:aws:tg1/abc123", "arn:aws:tg2/def456"]

    // --- Check Point Settings ---
    gateway_version = "R81.20-BYOL"
    admin_shell = "/etc/cli.sh"
    gateway_password_hash = ""
    gateway_maintenance_mode_password_hash = "" # For R81.10 and below the gateway_password_hash is used also as maintenance-mode password.
    gateway_SICKey = "12345678"
    enable_instance_connect = false
    allow_upload_download = true
    enable_cloudwatch = false
    gateway_bootstrap_script = "echo 'this is bootstrap script' > /home/admin/bootstrap.txt"
    enable_ipv6 = false
}
```

## Inputs

| Name                                   | Description                                                                                                                                                                     | Type         | Allowed Values                                                                                                 |
|----------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|--------------|---------------------------------------------------------------------------------------------------------------|
| prefix                                 | (Optional) Instances name prefix                                                                                                                                                | string       |                                                                                                               |
| asg_name                               | Autoscaling Group name                                                                                                                                                         | string       |        **Default:** Check-Point-ASG-tf|
| vpc_id                                 | The VPC ID in which to deploy                                                                                                                                                  | string       |                                                                                                               |
| subnet_ids                             | List of public subnet IDs to launch resources into. Recommended at least 2                                                                                                     | list(string) |                                                                                                               |
| gateways_provision_address_type        | Determines if the gateways are provisioned using their private or public address.                                                                                              | string       | - private<br>- public<br>**Default:** private                                                                 |
| allocate_public_IP                     | Allocate a Public IP for gateway members.                                                                                                                                      | bool         | true/false<br>**Default:** false                                                                              |
| management_server                      | The name that represents the Security Management Server in the CME configuration                                                                                               | string       |                                                                                                               |
| configuration_template                 | Name of the provisioning template in the CME configuration                                                                                                                     | string       |                                                                                                               |
| gateway_name                           | The name tag of the Security Gateways instances                                                                                                                                | string       | **Default:** Check-Point-ASG-gateway-tf                                                                       |
| gateway_instance_type                  | The instance type of the Security Gateways                                                                                                                                    | string       | - c4.large <br/> - c4.xlarge <br/> - c5.large <br/> - c5.xlarge <br/> - c5.2xlarge <br/> - c5.4xlarge <br/> - c5.9xlarge <br/> - c5.12xlarge <br/> - c5.18xlarge <br/> - c5.24xlarge <br/> - c5n.large <br/> - c5n.xlarge <br/> - c5n.2xlarge <br/> - c5n.4xlarge <br/> - c5n.9xlarge <br/>  - c5n.18xlarge <br/>  - c5d.large <br/> - c5d.xlarge <br/> - c5d.2xlarge <br/> - c5d.4xlarge <br/> - c5d.9xlarge <br/> - c5d.12xlarge <br/>  - c5d.18xlarge <br/>  - c5d.24xlarge <br/> - m5.large <br/> - m5.xlarge <br/> - m5.2xlarge <br/> - m5.4xlarge <br/> - m5.8xlarge <br/> - m5.12xlarge <br/> - m5.16xlarge <br/> - m5.24xlarge <br/> - m6i.large <br/> - m6i.xlarge <br/> - m6i.2xlarge <br/> - m6i.4xlarge <br/> - m6i.8xlarge <br/> - m6i.12xlarge <br/> - m6i.16xlarge <br/> - m6i.24xlarge <br/> - m6i.32xlarge <br/> - c6i.large <br/> - c6i.xlarge <br/> - c6i.2xlarge <br/> - c6i.4xlarge <br/> - c6i.8xlarge <br/> - c6i.12xlarge <br/> - c6i.16xlarge <br/> - c6i.24xlarge <br/> - c6i.32xlarge <br/> - c6in.large <br/> - c6in.xlarge <br/> - c6in.2xlarge <br/> - c6in.4xlarge <br/> - c6in.8xlarge <br/> - c6in.12xlarge <br/> - c6in.16xlarge <br/> - c6in.24xlarge <br/> - c6in.32xlarge <br/> - r5.large <br/> - r5.xlarge <br/> - r5.2xlarge <br/> - r5.4xlarge <br/> - r5.8xlarge <br/> - r5.12xlarge <br/> - r5.16xlarge <br/> - r5.24xlarge <br/> - r5a.large <br/> - r5a.xlarge <br/> - r5a.2xlarge <br/> - r5a.4xlarge <br/> - r5a.8xlarge <br/> - r5a.12xlarge <br/> - r5a.16xlarge <br/> - r5a.24xlarge <br/> - r5b.large <br/> - r5b.xlarge <br/> - r5b.2xlarge <br/> - r5b.4xlarge <br/> - r5b.8xlarge <br/> - r5b.12xlarge <br/> - r5b.16xlarge <br/> - r5b.24xlarge <br/> - r5n.large <br/> - r5n.xlarge <br/> - r5n.2xlarge <br/> - r5n.4xlarge <br/> - r5n.8xlarge <br/> - r5n.12xlarge <br/> - r5n.16xlarge <br/> - r5n.24xlarge <br/> - r6i.large <br/> - r6i.xlarge <br/> - r6i.2xlarge <br/> - r6i.4xlarge <br/> - r6i.8xlarge <br/> - r6i.12xlarge <br/> - r6i.16xlarge <br/> - r6i.24xlarge <br/> - r6i.32xlarge <br/> - m6a.large <br/> - m6a.xlarge <br/> - m6a.2xlarge  <br/> - m6a.4xlarge <br/> - m6a.8xlarge <br/> - m6a.12xlarge <br/> - m6a.16xlarge <br/> - m6a.24xlarge <br/> - m6a.32xlarge <br/> - m6a.48xlarge <br/> **Default:** c5.xlarge                            |
| key_name                               | The EC2 Key Pair name to allow SSH access to the instances                                                                                                                     | string       |                                                                                                               |
| volume_size                            | Root volume size (GB) - minimum 100                                                                                                                                            | number       | **Default:** 100                                                                                              |
| enable_volume_encryption               | Encrypt Environment instances volume with default AWS KMS key                                                                                                                  | bool         | true/false<br>**Default:** true                                                                               |
| instances_tags                         | (Optional) A map of tags as key=value pairs. All tags will be added to all AutoScaling Group instances                                                                          | map(string)  | **Default:** {}                                                                                               |
| metadata_imdsv2_required               | Set true to deploy the instance with metadata v2 token required                                                                                                                | bool         | true/false<br>**Default:** true                                                                               |
| minimum_group_size                     | The minimum number of instances in the Auto Scaling group                                                                                                                      | number       | **Default:** 2                                                                                                |
| maximum_group_size                     | The maximum number of instances in the Auto Scaling group                                                                                                                      | number       | **Default:** 10                                                                                               |
| target_groups                          | (Optional) List of Target Group ARNs to associate with the Auto Scaling group                                                                                                  | list(string) |                                                                                                               |
| gateway_version                        | Gateway version and license                                                                                                                                                    | string       | - R81.20-BYOL<br>- R81.20-PAYG-NGTP<br>- R82-BYOL<br>**Default:** R81.20-BYOL                                 |
| admin_shell                            | Set the admin shell to enable advanced command line configuration                                                                                                              | string       | - /etc/cli.sh<br>- /bin/bash<br>- /bin/csh<br>**Default:** /etc/cli.sh                                        |
| gateway_password_hash                  | (Optional) Check Point recommends setting Admin user's password and maintenance-mode password for recovery purposes.                                                           | string       |                                                                                                               |
| gateway_SICKey                         | The Secure Internal Communication key for trusted connection between Check Point components (at least 8 alphanumeric characters)                                                | string       | **Default:** "12345678"                                                                                       |
| enable_instance_connect                | Enable SSH connection over AWS web console. Supporting regions can be found [here](https://aws.amazon.com/about-aws/whats-new/2019/06/introducing-amazon-ec2-instance-connect/) | bool         | true/false<br>**Default:** false                                                                              |
| allow_upload_download                  | Automatically download Blade Contracts and other important data. Improve product experience by sending data to Check Point                                                      | bool         | true/false<br>**Default:** true                                                                               |
| enable_cloudwatch                      | Report Check Point specific CloudWatch metrics                                                                                                                                | bool         | true/false<br>**Default:** false                                                                              |
| gateway_bootstrap_script               | (Optional) Semicolon (;) separated commands to run on the initial boot                                                                                                         | string       |                                                                                                               |
| volume_type                            | General Purpose SSD Volume Type                                                                                                                                               | string       | - gp3<br>- gp2<br>**Default:** gp3                                                                            |
| gateway_maintenance_mode_password_hash | (Optional) Maintenance-mode password for recovery purposes.                                                                                                                    | string       |                                                                                                               |
 security_rules | List of security rules for ingress and egress.                                                         | list(object({<br/>    direction   = string    <br/>from_port   = any    <br/>to_port     = any <br/>protocol    = any <br/>cidr_blocks = list(any)<br/>}))         | **Default:** []|
| enable_ipv6                            | Enables dual-stack networking (IPv4 and IPv6) for the GWLB, [Please see version compatibility in the following guide](https://sc1.checkpoint.com/documents/IaaS/WebAdminGuides/EN/CP_CloudGuard_Network_for_AWS_Gateway_Load_Balancer_ASG/Content/Topics-AWS-GWLB-ASG-DG/IPv6-Support.htm)    | bool         | true/false<br>**Default:** false 


## Outputs
To display the outputs defined by the module, create an `outputs.tf` file with the following structure:
```
output "instance_public_ip" {
  value = module.{module_name}.instance_public_ip
}
```
| Name                                           | Description                                                       |
|------------------------------------------------|-------------------------------------------------------------------|
| 20250508                                       |Added support for IPv6 traffic settings                            |                                                                                                                           |
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
