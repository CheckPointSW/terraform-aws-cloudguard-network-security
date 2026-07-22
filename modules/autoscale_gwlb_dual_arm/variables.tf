// Module: Check Point CloudGuard Network Auto Scaling Group into an existing VPC

// --- Environment ---
variable "deployment_prefix" {
  type = string
  description = "Prefix for all resource names (ASG, GWLB, Target Group, Gateway). Will have suffixes added: -asg-tf, -gwlb-tf, -tg-tf, -gateway-tf"
  default = "chkp"
  validation {
    condition     = length(var.deployment_prefix) <= 20
    error_message = "deployment_prefix must be at most 20 characters to allow for suffixes."
  }
}

// --- VPC Network Configuration ---
variable "vpc_id" {
  type = string
}
variable "gateways_private_subnets" {
  type = list(string)
  description = "List of public subnet IDs to launch resources into. Recommended at least 2"
}
variable "gateways_public_subnets" {
  type = list(string)
  description = "Select at least 2 public subnets in the VPC. If you choose to deploy a Security Management Server it will be deployed in the first subnet"
}
// --- Automatic Provisioning with Security Management Server Settings ---
variable "gateways_provision_address_type" {
  type = string
  description = "Determines if the gateways are provisioned using their private or public address"
  default = "private"
}

variable "management_server" {
  type = string
  description = "The name that represents the Security Management Server in the CME configuration"
}
variable "configuration_template" {
  type = string
  description = "Name of the provisioning template in the CME configuration"
  validation {
    condition     = length(var.configuration_template) < 31
    error_message = "The configuration_template name can not exceed 30 characters."
  }
}

// --- EC2 Instances Configuration ---
variable "gateway_instance_type" {
  type = string
  description = "The instance type of the Security Gateways"
  default = "c6in.xlarge"
}
module "validate_instance_type" {
  source = "../instance_type"

  chkp_type = "gateway"
  instance_type = var.gateway_instance_type
}
variable "key_name" {
  type = string
  description = "The EC2 Key Pair name to allow SSH access to the instances"
}
variable "volume_size" {
  type = number
  description = "Root volume size (GB) - minimum 100"
  default = 200
}
resource "null_resource" "volume_size_too_small" {
  // Will fail if var.volume_size is less than 100
  count = var.volume_size >= 100 ? 0 : "variable volume_size must be at least 100"
}
variable "enable_volume_encryption" {
  type = bool
  description = "Encrypt Environment instances volume with default AWS KMS key"
  default = true
}
variable "instances_tags" {
  type = map(string)
  description = "(Optional) A map of tags as key=value pairs. All tags will be added on all Auto Scaling Group instances"
  default = {}
}
variable "custom_tags" {
  type = map(string)
  description = "(Optional) A map of custom tags as key=value pairs. All tags are added to every resource created by this module (Auto Scaling Group instances, volumes, network interfaces, and the security group). Note: the second network interface and Elastic IP attached at runtime by the dual-arm Lambda are not covered by this input."
  default = {}
}
variable "metadata_imdsv2_required" {
  type = bool
  description = "Set true to deploy the instance with metadata v2 token required"
  default = true
}

// --- Auto Scaling Configuration ---
variable "minimum_group_size" {
  type = number
  description = "The minimum number of instances in the Auto Scaling group"
  default = 2
}
variable "maximum_group_size" {
  type = number
  description = "The maximum number of instances in the Auto Scaling group"
  default = 10
}
variable "target_groups" {
  type = list(string)
  description = "(Optional) List of Target Group ARNs to associate with the Auto Scaling group"
  default = []
}

// --- Check Point Settings ---
variable "gateway_version" {
  type = string
  description =  "Gateway version and license"
  default = "R82-BYOL"
}
module "validate_gateway_version" {
  source = "../version_license"

  chkp_type = "gwlb_gw"
  version_license = var.gateway_version
}
variable "admin_shell" {
  type = string
  description = "Set the admin shell to enable advanced command line configuration"
  default = "/etc/cli.sh"
}
variable "gateway_password_hash" {
  type = string
  description = "(Optional) Admin user's password hash (use command 'openssl passwd -6 PASSWORD' to get the PASSWORD's hash)"
  default = ""
}
variable "gateway_maintenance_mode_password_hash" {
  description = "(optional) Check Point recommends setting Admin user's password and maintenance-mode password for recovery purposes. For R81.10 and below the Admin user's password is used also as maintenance-mode password. (To generate a password hash use the command 'grub2-mkpasswd-pbkdf2' on Linux and paste it here)."
  type = string
  default = ""
}
variable "gateway_SICKey" {
  type = string
  description = "The Secure Internal Communication key for trusted connection between Check Point components (at least 8 alphanumeric characters)"
}
variable "enable_instance_connect" {
  type = bool
  description = "Enable SSH connection over AWS web console"
  default = false
}
variable "allow_upload_download" {
  type = bool
  description = "Automatically download Blade Contracts and other important data. Improve product experience by sending data to Check Point"
  default = true
}
variable "enable_cloudwatch" {
  type = bool
  description = "Report Check Point specific CloudWatch metrics"
  default = false
}
variable "gateway_bootstrap_script" {
  type = string
  description = "(Optional) Semicolon (;) separated commands to run on the initial boot"
  default = ""
}

variable "volume_type" {
  type = string
  description = "General Purpose SSD Volume Type"
  default = "gp3"
}
variable "gateways_security_rules" {
  description = "List of security rules for ingress and egress"
  type        = list(object({
    direction   = string  # "ingress" or "egress"
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
  }))
  default = []
}
variable "ip_mode" {
  type = string
  description = "IP mode of AWS resources."
  default = "IPv4"
  validation {
    condition     = contains(["IPv4", "DualStack"], var.ip_mode)
    error_message = "The ip_mode value must be one of: IPv4 or DualStack."
  }
}
variable "existing_security_group_id" {
  type = string
  description = "(Optional) The ID of an existing Security Group to use (e.g. sg-0123456789abcdef0). If empty, a new Security Group open to all traffic (0.0.0.0/0) will be created"
  default = ""
  validation {
    condition     = can(regex("^(sg-[0-9a-f]{8,17})?$", var.existing_security_group_id))
    error_message = "The existing_security_group_id must be a valid Security Group ID (e.g. sg-0123456789abcdef0) or left empty."
  }
}
variable "lambda_auto_update" {
  type = bool
  description = "When true, the Lambda function will always check for the newest version from S3 on each execution and update the environment variable. When false (default), the Lambda will pin to the latest version on first run and stay with it."
  default = false
}
variable "ipam_pool_id" {
  type = string
  description = "(Optional) The ID of an IPAM pool to allocate Elastic IPs from. If not provided, EIPs will be allocated from Amazon's pool of public IPv4 addresses."
  default = ""
}

// Validate IPAM pool exists if provided
data "aws_vpc_ipam_pool" "validate_ipam_pool" {
  count = var.ipam_pool_id != "" ? 1 : 0
  
  ipam_pool_id = var.ipam_pool_id
}

// Add lifecycle check to ensure it fails early
resource "null_resource" "ipam_pool_validation" {
  count = var.ipam_pool_id != "" ? 1 : 0
  
  lifecycle {
    precondition {
      condition     = var.ipam_pool_id != "" ? length(data.aws_vpc_ipam_pool.validate_ipam_pool) > 0 : true
      error_message = "The specified IPAM pool ID '${var.ipam_pool_id}' does not exist or is not accessible."
    }
  }
}


