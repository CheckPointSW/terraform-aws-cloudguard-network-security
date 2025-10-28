module "launch_vpc" {
  source = "../vpc"

  vpc_cidr = var.vpc_cidr
  public_subnets_map = var.public_subnets_map
  private_subnets_map = var.private_subnets_map
  subnets_bit_length = var.subnets_bit_length
}

module "launch_autoscale_into_vpc" {
  source = "../autoscale"

  vpc_id = module.launch_vpc.vpc_id
  subnet_ids = module.launch_vpc.public_subnets_ids_list

  // --- General Settings ---
  prefix = var.prefix
  asg_name = var.asg_name
  gateway_name = var.gateway_name
  gateway_instance_type = var.gateway_instance_type
  key_name = var.key_name
  enable_volume_encryption = var.enable_volume_encryption
  volume_size = var.volume_size
  enable_instance_connect = var.enable_instance_connect
  metadata_imdsv2_required = var.metadata_imdsv2_required
  instances_tags = var.instances_tags

  // --- Auto Scaling Configuration ---
  minimum_group_size = var.minimum_group_size
  maximum_group_size = var.maximum_group_size
  target_groups = var.target_groups

  // --- Check Point Settings ---
  gateway_version = var.gateway_version
  gateway_password_hash = var.gateway_password_hash
  gateway_maintenance_mode_password_hash = var.gateway_maintenance_mode_password_hash
  gateway_SICKey = var.gateway_SICKey
  allow_upload_download = var.allow_upload_download
  enable_cloudwatch = var.enable_cloudwatch
  gateway_bootstrap_script = var.gateway_bootstrap_script
  admin_shell = var.admin_shell

  // --- Management Configuration ---
  management_server = var.management_server
  configuration_template = var.configuration_template
  gateways_provision_address_type = var.gateways_provision_address_type

  // --- Proxy ELB Configuration ---
  proxy_elb_type = var.proxy_elb_type
  proxy_elb_port = var.proxy_elb_port
  proxy_elb_clients = var.proxy_elb_clients

  // --- Security Rules ---
  security_rules = var.security_rules
}
