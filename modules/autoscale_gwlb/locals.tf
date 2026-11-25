locals {

  gateway_name = var.gateway_name == null ? (
    var.resource_name_base != "" ? var.resource_name_base : "Check-Point-ASG-gateway-tf"
  ) : (
    var.gateway_name == "" && var.resource_name_base != "" ? var.resource_name_base : var.gateway_name
  )
  pooled_asg_name = var.asg_name == null ? (
    var.resource_name_base != "" ? var.resource_name_base : "Check-Point-ASG-tf"
  ) : (
    var.asg_name == "" && var.resource_name_base != "" ? var.resource_name_base : var.asg_name
  )

  asg_name = format("%s%s", var.prefix != "" ? format("%s-", var.prefix) : "", local.use_per_az_asgs ? local.gateway_name : local.pooled_asg_name)

  cme_tags = {
    x-chkp-tags     = format("management=%s:template=%s:ip-address=%s", var.management_server, var.configuration_template, var.gateways_provision_address_type)
    x-chkp-topology = "internal"
    x-chkp-solution = "autoscale_gwlb"
  }

  prm_tags = merge(var.custom_tags, var.instances_tags, local.cme_tags, {
    aws-apn-id = "pc:${module.amis.product_code}"
  })

  create_iam_role = var.existing_iam_instance_profile_name == "" && (var.create_asg_per_az || var.enable_cloudwatch) ? 1 : 0
  instance_profile_name = var.existing_iam_instance_profile_name != "" ? var.existing_iam_instance_profile_name : one(aws_iam_instance_profile.instance_profile[*].name)

  gateway_iam_role_name             = var.resource_name_base != "" ? "${var.resource_name_base}-GatewayRole" : null
  gateway_iam_instance_profile_name = var.resource_name_base != "" ? "${var.resource_name_base}-GatewayInstanceProfile" : null

  existing_gateway_security_group_ids = var.existing_security_group_id == "" || var.existing_security_group_id == null ? [] : flatten([var.existing_security_group_id])
  create_permissive_sg = length(local.existing_gateway_security_group_ids) == 0 ? 1 : 0

  launch_template_security_group_ids = length(local.existing_gateway_security_group_ids) > 0 ? local.existing_gateway_security_group_ids : aws_security_group.permissive_sg[*].id

  use_per_az_asgs   = var.create_asg_per_az
  per_az_groups    = var.create_asg_per_az ? var.az_instance_types : {}
  legacy_asg_count = var.create_asg_per_az ? 0 : 1

  gateways_provision_address_type_allowed_values = [
    "public",
    "private"
  ]
  // Will fail if var.gateways_provision_address_type is invalid
  validate_gateways_provision_address_type = index(local.gateways_provision_address_type_allowed_values, var.gateways_provision_address_type)

  admin_shell_allowed_values = [
    "/etc/cli.sh",
    "/bin/bash",
    "/bin/csh",
    "/bin/tcsh"
  ]
  // Will fail if var.admin_shell is invalid
  validate_admin_shell = index(local.admin_shell_allowed_values, var.admin_shell)

  regex_valid_key_name = "[\\S\\s]+[\\S]+"
  regex_key_name_result=regex(local.regex_valid_key_name, var.key_name) == var.key_name ? 0 : "Variable [key_name] must be a none empty string"

  regex_valid_sic_key = "^[a-zA-Z0-9]{8,}$"
  // Will fail if var.gateway_SICKey is invalid
  regex_sic_result = regex(local.regex_valid_sic_key, var.gateway_SICKey) == var.gateway_SICKey ? 0 : "Variable [gateway_SICKey] must be at least 8 alphanumeric characters"

  regex_valid_gateway_password_hash = "^[\\$\\./a-zA-Z0-9]*$"
  // Will fail if var.gateway_password_hash is invalid
  regex_gateway_password_hash = regex(local.regex_valid_gateway_password_hash, var.gateway_password_hash) == var.gateway_password_hash ? 0 : "Variable [gateway_password_hash] must be a valid password hash"
  regex_gateway_maintenance_mode_password_hash = regex(local.regex_valid_gateway_password_hash, var.gateway_maintenance_mode_password_hash) == var.gateway_maintenance_mode_password_hash ? 0 : "Variable [gateway_maintenance_mode_password_hash] must be a valid password hash"

  regex_valid_cidr_range = "^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)(/(3[0-2]|2[0-9]|1[0-9]|[0-9]))?$"

  # IPv6 configuration helpers
  ipv6_enabled = var.ip_mode != "IPv4"
  ipv4_enabled = var.ip_mode != "IPv6"

  tags_asg_format = null_resource.tags_as_list_of_maps.*.triggers

  //Splits the version and licence and returns the os version
  version_split = element(split("-", var.gateway_version), 0)

  gateway_bootstrap_script64 = base64encode(var.gateway_bootstrap_script)
  gateway_SICkey_base64 = base64encode(var.gateway_SICKey)
  gateway_password_hash_base64 = base64encode(var.gateway_password_hash)
  maintenance_mode_password_hash_base64 = base64encode(var.gateway_maintenance_mode_password_hash)

  // Diagnostics IPv6
  template_name = join("", [
    "autoscale_gwlb",
    var.ip_mode == "DualStack" ? "_dual_stack" :
    var.ip_mode == "IPv6"      ? "_ipv6" :
    ""
  ])
}
resource "null_resource" "tags_as_list_of_maps" {
  count = length(keys(var.instances_tags))

  triggers = {
    "key" = keys(var.instances_tags)[count.index]
    "value" = values(var.instances_tags)[count.index]
    "propagate_at_launch" = "true"
  }
}
