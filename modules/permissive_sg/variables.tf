variable "vpc_id" {
  type = string
}
variable "resources_tag_name" {
  type = string
  description = "(Optional)"
  default = ""
}
variable "gateway_name" {
  type = string
  description = "(Optional) The name tag of the Security Gateway instances"
  default = "Check-Point-Gateway-tf"
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
    condition     = contains(["IPv4", "DualStack", "IPv6"], var.ip_mode)
    error_message = "The ip_mode value must be one of: IPv4, DualStack, or IPv6."
  }
}