module "launch_vpc" {
  source = "../vpc"

  vpc_cidr = var.vpc_cidr
  public_subnets_map = var.public_subnets_map
  private_subnets_map = var.private_subnets_map
  tgw_subnets_map = var.tgw_subnets_map
  subnets_bit_length = var.subnets_bit_length
  deployment_prefix = var.deployment_prefix
  ip_mode = var.ip_mode
}
module "tgw_gwlb"{
  source = "../tgw_gwlb_dual_arm"

  vpc_id = module.launch_vpc.vpc_id
  gateways_private_subnets = module.launch_vpc.private_subnets_ids_list
  gateways_public_subnets = module.launch_vpc.public_subnets_ids_list
  number_of_AZs = var.number_of_AZs
  availability_zones = var.availability_zones
  internet_gateway_id = module.launch_vpc.aws_igw

  transit_gateway_attachment_subnet_1_id =  element(module.launch_vpc.tgw_subnets_ids_list, 0)
  transit_gateway_attachment_subnet_2_id =  element(module.launch_vpc.tgw_subnets_ids_list, 1)
  transit_gateway_attachment_subnet_3_id = var.number_of_AZs >= 3 ?  element(module.launch_vpc.tgw_subnets_ids_list, 2) : ""
  transit_gateway_attachment_subnet_4_id = var.number_of_AZs >= 4 ? element(module.launch_vpc.tgw_subnets_ids_list, 3) : ""

  gwlbe_subnet_1_cidr = var.gwlbe_subnet_1_cidr
  gwlbe_subnet_2_cidr = var.gwlbe_subnet_2_cidr
  gwlbe_subnet_3_cidr = var.gwlbe_subnet_3_cidr
  gwlbe_subnet_4_cidr = var.gwlbe_subnet_4_cidr
  management_subnet_cidr = var.management_subnet_cidr

  // --- General Settings ---
  key_name = var.key_name
  enable_volume_encryption = var.enable_volume_encryption
  volume_size = var.volume_size
  enable_instance_connect = var.enable_instance_connect
  disable_instance_termination = var.disable_instance_termination
  metadata_imdsv2_required = var.metadata_imdsv2_required
  allow_upload_download = var.allow_upload_download
  management_server = var.management_server
  configuration_template = var.configuration_template
  admin_shell = var.admin_shell

  // --- Gateway Load Balancer Configuration ---
  deployment_prefix = var.deployment_prefix
  enable_cross_zone_load_balancing = var.enable_cross_zone_load_balancing

  // --- Check Point CloudGuard IaaS Security Gateways Auto Scaling Group Configuration ---
  gateway_instance_type = var.gateway_instance_type
  minimum_group_size = var.minimum_group_size
  maximum_group_size = var.maximum_group_size
  gateway_version = var.gateway_version
  gateway_password_hash = var.gateway_password_hash
  gateway_maintenance_mode_password_hash = var.gateway_maintenance_mode_password_hash
  gateway_SICKey = var.gateway_SICKey
  gateways_provision_address_type = var.gateways_provision_address_type
  enable_cloudwatch = var.enable_cloudwatch
  gateway_bootstrap_script = var.gateway_bootstrap_script

  // --- Check Point CloudGuard IaaS Security Management Server Configuration ---
  management_deploy = var.management_deploy
  management_instance_type = var.management_instance_type
  management_version = var.management_version
  management_password_hash = var.management_password_hash
  management_maintenance_mode_password_hash = var.management_maintenance_mode_password_hash
  gateways_policy = var.gateways_policy
  gateway_management = var.gateway_management
  admin_cidr = var.admin_cidr
  gateways_addresses = var.gateways_addresses

  volume_type = var.volume_type
  lambda_auto_update = var.lambda_auto_update
  ipam_pool_id = var.ipam_pool_id
  ip_mode = var.ip_mode
  gateways_security_rules = var.gateways_security_rules
  management_security_rules = var.management_security_rules
}