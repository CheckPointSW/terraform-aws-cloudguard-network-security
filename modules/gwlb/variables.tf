// Module: Check Point CloudGuard Network Gateway Load Balancer into an existing VPC

// --- Network Configuration ---
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

variable "vpc_id" {
  type = string
}
variable "subnet_ids" {
  type = list(string)
  description = "List of public subnet IDs to launch resources into. Recommended at least 2"
}

// --- General Settings ---
variable "key_name" {
  type = string
  description = "The EC2 Key Pair name to allow SSH access to the instances"
}
variable "enable_volume_encryption" {
  type = bool
  description = "Encrypt Environment instances volume with default AWS KMS key"
  default = true
}
variable "volume_size" {
  type = number
  description = "Gateway root volume size (GB), minimum 100. Applies only when create_asg_per_az=true; otherwise gateways use 200 GB."
  default = 200
}
resource "null_resource" "volume_size_too_small" {
  // Will fail if var.volume_size is less than 100
  count = var.volume_size >= 100 ? 0 : "variable volume_size must be at least 100"
}
variable "enable_instance_connect" {
  type = bool
  description = "Enable SSH connection over AWS web console"
  default = false
}
variable "disable_instance_termination" {
  type = bool
  description = "Prevents an instance from accidental termination"
  default = false
}
variable "metadata_imdsv2_required" {
  type = bool
  description = "Set true to deploy the instance with metadata v2 token required"
  default = true
}
variable "allow_upload_download" {
  type = bool
  description = "Automatically download Blade Contracts and other important data. Improve product experience by sending data to Check Point"
  default = true
}
variable "management_server" {
  type = string
  description = "The name that represents the Security Management Server in the automatic provisioning configuration."
}
variable "configuration_template" {
  type = string
  description = "A name of a gateway configuration template in the automatic provisioning configuration."
  validation {
    condition     = length(var.configuration_template) < 31
    error_message = "The configuration_template name can not exceed 30 characters"
  }
}
variable "admin_shell" {
  type = string
  description = "Set the admin shell to enable advanced command line configuration"
  default = "/etc/cli.sh"
}

// --- Gateway Load Balancer Configuration ---

variable "gateway_load_balancer_name" {
  type = string
  description =  "Optional GWLB name, at most 32 characters. With a nonempty resource_name_base, a nonempty explicit name wins; null or empty falls back to the base name. Empty resource_name_base preserves the legacy generated naming behavior and the effective gwlb1 input default."
  default = null
}
resource "null_resource" "gateway_load_balancer_name_too_long" {
  // Will fail if gateway_load_balancer_name more than 32
  count = length(local.gateway_load_balancer_name) <= 32 ? 0 : "variable gateway_load_balancer_name must be at most 32"
}
variable "target_group_name" {
  type = string
  description =  "Optional target-group name, at most 32 characters. With a nonempty resource_name_base, a nonempty explicit name wins; null or empty falls back to the base name. Empty resource_name_base preserves the legacy generated naming behavior and the effective tg1 input default."
  default = null
}
resource "null_resource" "target_group_name_too_long" {
  // Will fail if target_group_name more than 32
  count = length(local.target_group_name) <= 32 ? 0 : "variable target_group_name must be at most 32"
}
variable "connection_acceptance_required" {
  type = bool
  description =  "Indicate whether requests from service consumers to create an endpoint to your service must be accepted. Default is set to false(acceptance not required)."
  default = false
}
variable "enable_cross_zone_load_balancing" {
  type = bool
  description =  "Select 'true' to enable cross-az load balancing. NOTE! this may cause a spike in cross-az charges."
  default = true
}

// --- Check Point CloudGuard IaaS Security Gateways Auto Scaling Group Configuration ---

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
variable "minimum_group_size" {
  type = number
  description = "The minimal number of Security Gateways."
  default = 2
}
variable "maximum_group_size" {
  type = number
  description = "The maximal number of Security Gateways."
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
variable "gateway_version" {
  type = string
  description =  "The version and license to install on the Security Gateways."
  default = "R81.20-BYOL"
}
module "validate_gateway_version" {
  source = "../version_license"

  chkp_type = "gwlb_gw"
  version_license = var.gateway_version
}
variable "gateway_password_hash" {
  type = string
  description = "(Optional) Admin user's password hash (use command 'openssl passwd -6 PASSWORD' to get the PASSWORD's hash)"
  default = ""
  sensitive = true
}
variable "gateway_maintenance_mode_password_hash" {
  description = "Maintenance mode password hash for the gateway instances, relevant only for R81.20 and higher versions"
  type = string
  default = ""
  sensitive = true
}
variable "gateway_SICKey" {
  type = string
  description = "The Secure Internal Communication key for trusted connection between Check Point components (at least 8 alphanumeric characters)"
  sensitive = true
}

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

variable "enable_cloudwatch" {
  type = bool
  description = "Report Check Point specific CloudWatch metrics."
  default = false
}

variable "gateway_bootstrap_script" {
  type = string
  description = "(Optional) An optional script with semicolon (;) separated commands to run on the initial boot"
  default = ""
}

// --- Check Point CloudGuard IaaS Security Management Server Configuration ---

variable "management_deploy" {
  type = bool
  description = "Select 'false' to use an existing Security Management Server or to deploy one later and to ignore the other parameters of this section"
  default = true
}
variable "management_instance_type" {
  type = string
  description = "The EC2 instance type of the Security Management Server"
  default = "m5.xlarge"
}
module "validate_management_instance_type" {
  source = "../instance_type"

  chkp_type = "management"
  instance_type = var.management_instance_type
}
variable "management_version" {
  type = string
  description =  "The license to install on the Security Management Server"
  default = "R81.20-BYOL"
}
module "validate_management_version" {
  source = "../version_license"

  chkp_type = "management"
  version_license = var.management_version
}
variable "management_password_hash" {
  type = string
  description = "(Optional) Admin user's password hash (use command 'openssl passwd -6 PASSWORD' to get the PASSWORD's hash)"
  default = ""
  sensitive = true
}
variable "management_maintenance_mode_password_hash" {
  description = "Maintenance mode password hash for the management instance, relevant only for R81.20 and higher versions"
  type = string
  default = ""
  sensitive = true
}
variable "gateways_policy" {
  type = string
  description = "The name of the Security Policy package to be installed on the gateways in the Security Gateways Auto Scaling group"
  default = "Standard"
}
variable "gateway_management" {
  type = string
  description = "Select 'Over the internet' if any of the gateways you wish to manage are not directly accessed via their private IP address."
  default = "Locally managed"
}
variable "admin_cidr" {
  type = string
  description = "Allow web, ssh, and graphical clients only from this network to communicate with the Security Management Server"
}
variable "gateways_addresses" {
  type = string
  description = "Allow gateways only from this network to communicate with the Security Management Server"
}

// --- Other parameters ---
variable "volume_type" {
  type = string
  description = "General Purpose SSD Volume Type"
  default = "gp3"
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
variable "custom_tags" {
  type = map(string)
  description = "(Optional) A map of custom tags as key=value pairs. All tags are added to every resource created by the Gateway Load Balancer module (the load balancer, target group, listener, VPC endpoint service, and the Auto Scaling Group resources). Gateway IAM role/profile tags apply only with create_asg_per_az=true."
  default = {}
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


variable "create_asg_per_az" {
  type        = bool
  default     = false
  description = "False (default) creates one ASG across selected AZs and requires an empty az_instance_types map. True requires gateway_instance_type to be omitted or null and a nonempty instance type in each map entry. It creates one ASG per map entry and a shared gateway IAM role/profile; an empty map creates no ASGs but still creates IAM resources. When used through gwlb_master, public-subnet routing is unchanged: one route table and association per configured subnet, with default routes when enabled, in either ASG mode. The launch template is always created."
}


variable "instances_tags" {
  type        = map(string)
  default     = {}
  description = "Additional gateway instance tags propagated by the ASG. Override custom_tags on instances; generated Name, CME and Marketplace tags take precedence. These do not tag volumes or network interfaces."
}

variable "az_instance_types" {
  type = map(object({
    subnet_id     = string
    instance_type = string
  }))
  description = "Gateway groups keyed by AZ with subnet_id and instance_type. Each group starts at minimum_group_size and scales up to maximum_group_size. Only valid with create_asg_per_az=true. Each instance_type must be nonempty; gateway_instance_type must be omitted or null."
  default     = {}
  nullable    = false

  validation {
    condition     = alltrue([for v in values(var.az_instance_types) : try(length(trimspace(v.instance_type)) > 0, false)])
    error_message = "Each az_instance_types entry must provide a nonempty instance_type; there is no gateway_instance_type fallback."
  }

  validation {
    condition     = alltrue([for k, v in var.az_instance_types : can(regex("^subnet-[0-9a-f]{8,17}$", v.subnet_id))])
    error_message = "Each az_instance_types entry must name a subnet id (subnet-<hex>)."
  }
}

variable "resource_name_base" {
  type = string
  default = ""
  nullable = false
  description = "Optional base for resource names. Empty preserves legacy naming, including existing explicit inputs. Nonempty enables explicit resource names with this base as fallback; GWLB and target-group names use the base unchanged and must fit 32 characters; supply explicit shorter names for a longer base. Exact launch-template naming uses gateway_name or this base unchanged. Created gateway IAM identities use this base with -GatewayRole and -GatewayInstanceProfile suffixes. Changing naming mode can replace existing named resources."
}
