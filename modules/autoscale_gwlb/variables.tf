// Module: Check Point CloudGuard Network Auto Scaling Group into an existing VPC

// --- Environment ---
variable "existing_iam_instance_profile_name" {
  description = "Optional existing EC2 instance-profile name for gateways. Nonempty skips module-owned gateway IAM creation and CloudWatch policy attachment; the caller owns permissions on the supplied profile's role. Empty preserves existing IAM behavior."
  type        = string
  default     = ""
  nullable    = false
  validation {
    condition     = var.existing_iam_instance_profile_name == "" || can(regex("^[A-Za-z0-9_+=,.@-]{1,128}$", var.existing_iam_instance_profile_name))
    error_message = "existing_iam_instance_profile_name must be empty or a valid IAM instance-profile name, not an ARN."
  }
}

variable "prefix" {
  type = string
  description = "(Optional) Instances name prefix"
  default = ""
    validation {
    condition     = length(var.prefix) <= 40
    error_message = "Prefix can not exceed 40 characters."
  }
}
variable "asg_name" {
  type = string
  description = "Optional pooled-ASG name prefix. Null uses resource_name_base when supplied, otherwise the historical Check-Point-ASG-tf prefix. Explicit values retain priority."
  default = null
  validation {
    condition     = var.asg_name == null ? true : length(var.asg_name) <= 100
    error_message = "Autoscaling Group name can not exceed 100 characters."
  }
}

// --- VPC Network Configuration ---
variable "vpc_id" {
  type = string
}
variable "subnet_ids" {
  type = list(string)
  description = "List of public subnet IDs to launch resources into. Recommended at least 2"
}

// --- Automatic Provisioning with Security Management Server Settings ---
variable "gateways_provision_address_type" {
  type = string
  description = "Determines if the gateways are provisioned using their private or public address"
  default = "private"
}

variable "allocate_public_IP" {
  type = bool
  description = "Allocate an Elastic IP for security gateway."
  default = false
}

resource "null_resource" "invalid_allocation" {
  // Will fail if var.gateways_provision_address_type is public and var.allocate_public_IP is false
  count = var.gateways_provision_address_type != "public" ? 0 : var.allocate_public_IP == true ? 0 : "Gateway's selected to be provisioned by public IP, but [allocate_public_IP] parameter is false"
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
variable "gateway_name" {
  type = string
  description = "Optional gateway name. With resource_name_base set, a nonempty explicit value takes precedence for gateway naming and the exact launch-template name; null or empty uses resource_name_base, preserving all hyphens in the launch-template name. With an empty base, legacy gateway labels and generated launch-template naming are preserved."
  default = null
}
variable "gateway_instance_type" {
  type = string
  description = "Instance type for one ASG across selected AZs; null uses c6in.xlarge. Must be omitted or null when create_asg_per_az is true; set each AZ's type in az_instance_types instead."
  default     = null
}
module "validate_instance_type" {
  source = "../instance_type"
  count  = var.create_asg_per_az ? 0 : 1

  chkp_type = "gateway"
  instance_type = coalesce(var.gateway_instance_type, "c6in.xlarge")
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
  description = "(Optional) Gateway instance tags propagated by the ASG. Override custom_tags on instances; generated Name, CME and Marketplace tags take precedence."
  default = {}
}
variable "custom_tags" {
  type = map(string)
  description = "(Optional) A map of custom tags as key=value pairs. All tags are added to every resource created by this module (Auto Scaling Group instances, volumes, network interfaces, launch template, and the security group). Gateway IAM role/profile tags apply only with create_asg_per_az=true."
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
variable "scale_out_cpu_threshold" {
  type        = number
  description = "Scale out by one Security Gateway when the Auto Scaling group's average CPU utilization (%) stays above this value for 10 minutes. Keep scale_in_cpu_threshold at least 20 points lower to avoid flapping, e.g. 80/60 (default) or 70/45 for sustained large flows"
  default     = 80
  validation {
    condition     = var.scale_out_cpu_threshold >= 0 && var.scale_out_cpu_threshold <= 100
    error_message = "The scale_out_cpu_threshold value must be between 0 and 100."
  }
}
variable "scale_in_cpu_threshold" {
  type        = number
  description = "Scale in by one Security Gateway when the Auto Scaling group's average CPU utilization (%) stays below this value for 10 minutes. Must be lower than scale_out_cpu_threshold (checked at plan time); keep it at least 20 points lower to avoid flapping, e.g. 80/60 (default) or 70/45 for sustained large flows"
  default     = 60
  validation {
    condition     = var.scale_in_cpu_threshold >= 0 && var.scale_in_cpu_threshold <= 100
    error_message = "The scale_in_cpu_threshold value must be between 0 and 100."
  }
}
variable "scale_out_cooldown" {
  type        = number
  description = "Seconds the ASG waits after a scale-out before it scales again. Set it longer than a new Security Gateway takes to handle traffic, so one CPU spike does not add two gateways"
  default     = 300
  validation {
    condition     = var.scale_out_cooldown >= 0 && floor(var.scale_out_cooldown) == var.scale_out_cooldown
    error_message = "The scale_out_cooldown value must be a whole number of seconds, 0 or more."
  }
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
  default = "R81.20-BYOL"
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
  sensitive = true
}
variable "gateway_maintenance_mode_password_hash" {
  description = "(optional) Check Point recommends setting Admin user's password and maintenance-mode password for recovery purposes. For R81.10 and below the Admin user's password is used also as maintenance-mode password. (To generate a password hash use the command 'grub2-mkpasswd-pbkdf2' on Linux and paste it here)."
  type = string
  default = ""
  sensitive = true
}
variable "gateway_SICKey" {
  type = string
  description = "The Secure Internal Communication key for trusted connection between Check Point components (at least 8 alphanumeric characters)"
  sensitive = true
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
variable "security_rules" {
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
  type        = any
  description = "Existing gateway security group ID, or a list of IDs. Empty string (default) or an empty list supplies no existing groups. Supplied groups are attached to the gateways; the original permissive fallback is used only when no existing IDs are supplied."
  default     = ""
  validation {
    condition = can(regex("^(sg-[0-9a-f]{8,17})?$", var.existing_security_group_id)) ? true : try(
      can(tolist(var.existing_security_group_id)) && alltrue([
        for id in var.existing_security_group_id : can(regex("^sg-[0-9a-f]{8,17}$", id))
      ]), false
    )
    error_message = "existing_security_group_id must be empty, one valid security group ID, or a list of valid security group IDs (sg-<hex>)."
  }
}

variable "custom_ami" {
  type = string
  description = "(Optional) Custom AMI id to deploy. When empty, the AMI is resolved from amis.yaml by region and gateway_version"
  default = ""
  validation {
    condition     = can(regex("^(ami-[0-9a-f]{8,17})?$", var.custom_ami))
    error_message = "The custom_ami value must be empty or a valid AMI id (ami-xxxxxxxx)."
  }
}

variable "resource_name_base" {
  type = string
  default = ""
  nullable = false
  description = "Empty preserves the existing generated launch-template and ASG naming behavior. Nonempty uses gateway_name as the exact launch-template name, falling back to this base unchanged, and supplies unspecified gateway and single-ASG names. Explicit names take precedence. Created gateway IAM identities use this base with -GatewayRole and -GatewayInstanceProfile suffixes. Changing naming mode can replace named resources."
}
