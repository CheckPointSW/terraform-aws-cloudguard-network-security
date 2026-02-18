variable "private_route_table" {
  type = string
  description = "Sets '0.0.0.0/0' route to the Gateway instance in the specified route table (e.g. rtb-12a34567)"
  default=""
}
variable "internal_eni_id" {
  type = string
  description = "The internal-eni of the security gateway"
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