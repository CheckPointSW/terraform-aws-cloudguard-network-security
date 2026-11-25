variable "vpc_cidr" {
  type = string
}
variable "public_subnets_map" {
  type = map(string)
  description = "A map of pairs {availability-zone-name-or-id = subnet-suffix-number}. Keys must be all AZ names or all AZ IDs. Public subnet keys are detected automatically without changing resource keys; AZ-ID IPv6 subnets use /64 CIDRs. Each entry creates a subnet. Minimum 1 pair.  (e.g. {\"us-east-1a\" = 1} ) "
  validation {
    condition     = length(distinct([for zone in keys(var.public_subnets_map) : can(regex("-(az|wlz)[0-9]+$", zone))])) <= 1
    error_message = "public_subnets_map keys must be all AZ names (e.g. us-east-1a) or all AZ IDs (e.g. use1-az1), not a mix."
  }
}
variable "private_subnets_map" {
  type = map(string)
  description = "A map of pairs {availability-zone = subnet-suffix-number}. Each entry creates a subnet. Minimum 1 pair.  (e.g. {\"us-east-1a\" = 2} ) "

}
variable "tgw_subnets_map" {
  type = map(string)
  description = "A map of pairs {availability-zone = subnet-suffix-number}. Each entry creates a subnet. Minimum 1 pair.  (e.g. {\"us-east-1a\" = 2} ) "
  default = {}
}
variable "subnets_bit_length" {
  type = number
  description = "Number of additional bits with which to extend the vpc cidr. For example, if given a vpc_cidr ending in /16 and a subnets_bit_length value of 4, the resulting subnet address will have length /20."
}
variable "ip_mode" {
  type = string
  description = "IP mode of AWS resources."
  default = "IPv4"
  validation {
    condition     = contains(["IPv4", "DualStack", "IPv6"], var.ip_mode)
    error_message = "The ip_mode value must be one of: IPv4, DualStack, or IPv6."
  }
}
variable "deployment_prefix" {
  type = string
  description = "(Optional) Prefix to add to the VPC name"
  default = ""
}

variable "create_public_subnet_default_igw_route" {
  type = bool
  description = "(Optional) When true (default), add a 0.0.0.0/0 (and ::/0) route via the Internet Gateway to each per-AZ public route table. Set to false when the consuming template attaches a per-AZ NAT Gateway default route instead (gateways without public IPs)"
  default = true
}
variable "product_code" {
  type = string
  description = "(Optional) AWS Marketplace product code used for PRM resource tagging (aws-apn-id = pc:<product_code>). Leave empty to skip PRM tagging of VPC infrastructure."
  default = ""
}
variable "custom_tags" {
  type = map(string)
  description = "(Optional) A map of custom tags as key=value pairs. All tags are added to every resource created by this module (VPC, subnets, route tables, internet gateway)."
  default = {}
}

variable "enable_dns_hostnames" {
  type = bool
  description = "Enable DNS hostnames in the VPC. Null leaves the current AWS value unmanaged; true or false explicitly manages the setting."
  default = null
}
