module "autoscale" {
  source = "../autoscale"


  vpc_id = var.vpc_id
  subnet_ids = var.gateways_subnets
  gateway_name = var.gateway_name
  gateway_instance_type = var.gateway_instance_type
  key_name = var.key_name
  enable_volume_encryption = var.enable_volume_encryption
  enable_instance_connect = var.enable_instance_connect
  instances_tags = var.instances_tags
  metadata_imdsv2_required = var.metadata_imdsv2_required
  minimum_group_size = var.gateways_min_group_size
  maximum_group_size = var.gateways_max_group_size
  gateway_version = var.gateway_version
  gateway_password_hash = var.gateway_password_hash
  gateway_maintenance_mode_password_hash = var.gateway_maintenance_mode_password_hash
  gateway_SICKey = var.gateway_SICKey
  allow_upload_download = var.allow_upload_download
  enable_cloudwatch = var.enable_cloudwatch
  gateway_bootstrap_script = "echo -e '\nStarting Bootstrap script\n'; echo 'Adding tgw identifier to cloud-version'; cv_path='/etc/cloud-version'\n if test -f \"$cv_path\"; then sed -i '/template_name/c\\template_name: autoscale_tgw' /etc/cloud-version; fi; cv_json_path='/etc/cloud-version.json'\n cv_json_path_tmp='/etc/cloud-version-tmp.json'\n if test -f \"$cv_json_path\"; then cat \"$cv_json_path\" | jq '.template_name = \"'\"autoscale_tgw\"'\"' > \"$cv_json_path_tmp\"; mv \"$cv_json_path_tmp\" \"$cv_json_path\"; fi; echo 'Setting ASN to: ${var.asn}'; clish -c 'set as ${var.asn}' -s; echo -e '\nFinished Bootstrap script\n'"
  gateways_provision_address_type = var.control_gateway_over_public_or_private_address
  management_server =  var.management_server
  configuration_template = var.configuration_template
  existing_security_group_id = var.existing_security_group_id
  custom_tags = var.custom_tags
}

data "aws_region" "current"{}

module "management" {

  count = local.deploy_management_condition ? 1 : 0
  source = "../management"

  vpc_id = var.vpc_id
  subnet_id = var.gateways_subnets[0]
  management_name = var.management_server
  management_instance_type = var.management_instance_type
  key_name = var.key_name
  allocate_and_associate_eip = true
  volume_encryption = var.enable_volume_encryption ? "alias/aws/ebs" : ""
  enable_instance_connect = var.enable_instance_connect
  disable_instance_termination = var.disable_instance_termination
  metadata_imdsv2_required = var.metadata_imdsv2_required
  iam_permissions = var.management_permissions
  predefined_role = var.management_predefined_role
  management_version = var.management_version
  management_password_hash = var.management_password_hash
  management_maintenance_mode_password_hash = var.management_maintenance_mode_password_hash
  allow_upload_download = var.allow_upload_download
  admin_cidr = var.admin_cidr
  gateway_addresses = var.gateways_addresses
  gateway_management = var.gateway_management
  management_bootstrap_script = templatefile("${path.module}/tgw_mgmt_bootstrap.tftpl", {
    ManagementServer      = var.management_server
    ConfigurationTemplate = var.configuration_template
    SICKey                = var.gateway_SICKey
    Region                = data.aws_region.current.name
    GatewayVersion        = split("-", var.gateway_version)[0]
    GatewaysBlades        = var.gateways_blades
  })
}