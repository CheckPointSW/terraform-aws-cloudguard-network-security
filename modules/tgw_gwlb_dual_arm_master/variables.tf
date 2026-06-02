// Module: Check Point CloudGuard Network Gateway Load Balancer into an existing VPC

// ---VPC Network Configuration ---
variable "number_of_AZs" {
  type = number
  description = "Number of Availability Zones to use in the VPC. This must match your selections in the list of Availability Zones parameter"
  default = 2
}
variable "availability_zones"{
  type = list(string)
  description = "The Availability Zones (AZs) to use for the subnets in the VPC. Select two (the logical order is preserved)"
}
resource "null_resource" "tgw_availability_zones_validation1" {
  count = var.number_of_AZs == length(var.availability_zones) ? 0 : "variable availability_zones list size must be equal to variable num_of_AZs"
}
variable "vpc_cidr" {
  type = string
  description = "The CIDR block of the VPC"
  default = "10.0.0.0/16"
}
variable "public_subnets_map" {
  type = map(string)
  description = "A map of pairs {availability-zone = subnet-suffix-number}. Each entry creates a subnet. Minimum 2 pairs.  (e.g. {\"us-east-1a\" = 1} ) "
}
variable "private_subnets_map" {
  type = map(string)
  description = "A map of pairs {availability-zone = subnet-suffix-number}. Each entry creates a subnet. Minimum 2 pairs.  (e.g. {\"us-east-1a\" = 1} ) "
}
resource "null_resource" "tgw_availability_zones_validation2" {
  count = var.number_of_AZs == length(var.public_subnets_map) ? 0 : "variable public_subnets_map size must be equal to variable num_of_AZs"
}
variable "subnets_bit_length" {
  type = number
  description = "Number of additional bits with which to extend the vpc cidr. For example, if given a vpc_cidr ending in /16 and a subnets_bit_length value of 4, the resulting subnet address will have length /20"
}
variable "tgw_subnets_map" {
  type = map(string)
  description = "A map of pairs {availability-zone = subnet-suffix-number} for the tgw subnets. Each entry creates a subnet. Minimum 2 pairs.  (e.g. {\"us-east-1a\" = 1} ) "
}
resource "null_resource" "tgw_availability_zones_validation3" {
  count = var.number_of_AZs == length(var.tgw_subnets_map) ? 0 : "variable tgw_subnets_map size must be equal to variable num_of_AZs"
}
variable "gwlbe_subnet_1_cidr" {
  type = string
  description = "CIDR block for Gateway Loadbalancer endpoint subnet 1 located in the 1st Availability Zone"
  default = "10.0.14.0/24"
}
variable "gwlbe_subnet_2_cidr" {
  type = string
  description = "CIDR block for Gateway Loadbalancer endpoint subnet 2 located in the 2st Availability Zone"
  default = "10.0.24.0/24"
}
variable "gwlbe_subnet_3_cidr" {
  type = string
  description = "CIDR block for Gateway Loadbalancer endpoint subnet 3 located in the 3st Availability Zone"
  default = "10.0.34.0/24"
}
variable "gwlbe_subnet_4_cidr" {
  type = string
  description = "CIDR block for Gateway Loadbalancer endpoint subnet 4 located in the 4st Availability Zone"
  default = "10.0.44.0/24"
}
variable "management_subnet_cidr" {
  type = string
  description = "CIDR block for Management subnet"
  default = "10.0.55.0/24"
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
  description = "Root volume size (GB) - minimum 100"
  default = 200
}
resource "null_resource" "volume_size_too_small" {
  // Will fail if var.volume_size is less than 100
  count = var.volume_size >= 100 ? 0 : "variable volume_size must be at least 100"
}
variable "volume_type" {
  type = string
  description = "General Purpose SSD Volume Type"
  default = "gp3"
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
  default = "gwlb-management-server"
}
variable "configuration_template" {
  type = string
  description = "A name of a gateway configuration template in the automatic provisioning configuration."
  default = "gwlb-ASG-configuration"
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

variable "deployment_prefix" {
  type = string
  description = "Prefix for all resource names (ASG, GWLB, Target Group, Gateway). Will have suffixes added: -asg-tf, -gwlb-tf, -tg-tf, -gateway-tf"
  default = "chkp"
  validation {
    condition     = length(var.deployment_prefix) <= 20
    error_message = "deployment_prefix must be at most 20 characters to allow for suffixes."
  }
}
variable "enable_cross_zone_load_balancing" {
  type = bool
  description =  "Select 'true' to enable cross-az load balancing. NOTE! this may cause a spike in cross-az charges."
  default = true
}

// --- Check Point CloudGuard IaaS Security Gateways Auto Scaling Group Configuration ---

variable "gateway_instance_type" {
  type = string
  description = "The EC2 instance type for the Security Gateways."
  default = "c6in.xlarge"
}
module "validate_instance_type" {
  source = "../instance_type"

  chkp_type = "gateway"
  instance_type = var.gateway_instance_type
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
variable "gateway_version" {
  type = string
  description =  "The version and license to install on the Security Gateways."
  default = "R82-BYOL"
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
}
variable "gateway_maintenance_mode_password_hash" {
  description = "Maintenance mode password hash for the gateway instances, relevant only for R81.20 and higher versions"
  type = string
  default = ""
}
variable "gateway_SICKey" {
  type = string
  description = "The Secure Internal Communication key for trusted connection between Check Point components (at least 8 alphanumeric characters)"
}

variable "gateways_provision_address_type" {
  type = string
  description = "Determines if the gateways are provisioned using their private or public address"
  default = "private"
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
  default = "R82-BYOL"
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
}
variable "management_maintenance_mode_password_hash" {
  description = "Maintenance mode password hash for the management instance, relevant only for R81.20 and higher versions"
  type = string
  default = ""
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
variable "ip_mode" {
  type = string
  description = "IP mode of AWS resources."
  default = "IPv4"
  validation {
    condition     = contains(["IPv4", "DualStack"], var.ip_mode)
    error_message = "The ip_mode value must be one of: IPv4 or DualStack."
  }
}
variable "gateways_security_rules" {
  description = "List of security rules for ingress and egress for gateway instances"
  type        = list(object({
    direction   = string  # "ingress" or "egress"
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
  }))
  default = []
}
variable "management_security_rules" {
  description = "List of security rules for ingress and egress for management instance"
  type        = list(object({
    direction   = string  # "ingress" or "egress"
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
  }))
  default = []
}