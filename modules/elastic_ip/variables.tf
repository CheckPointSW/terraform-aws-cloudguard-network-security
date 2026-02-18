variable "allocate_and_associate_eip" {
  type = bool
  description = "If set to TRUE, an elastic IP will be allocated and associated with the launched instance"
  default = true
}
variable "external_eni_id" {
  type = string
  description = "The external-eni of the security gateway"
}
variable "private_ip_address" {
  type = string
  description = "The primary or secondary private IP address to associate with the Elastic IP address. "
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