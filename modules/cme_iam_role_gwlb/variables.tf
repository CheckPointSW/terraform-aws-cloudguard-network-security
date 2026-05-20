// Module: IAM role for selected permissions

variable "permissions" {
  type = string
  description = "The IAM role permissions"
  default = "Create with read permissions"
}
locals {
  permissions_allowed_values = [
    "Create with assume role permissions (specify an STS role ARN)",
    "Create with read permissions",
    "Create with read-write permissions"]
  // Will fail if var.permissions is invalid
  validate_permissions = index(local.permissions_allowed_values, var.permissions)
}
variable "sts_roles" {
  type = list(string)
  description = "The IAM role will be able to assume these STS Roles (map of string ARNs)"
  default = []
}
variable "trusted_account" {
  type = string
  description = "A 12 digits number that represents the ID of a trusted account. IAM users in this account will be able assume the IAM role and receive the permissions attached to it"
  default = ""
}
variable "external_id" {
  type = string
  description = "External ID required for cross-account role assumption (confused deputy protection). Mandatory when trusted_account is set; ignored when trusted_account is empty."
  default = ""
}
