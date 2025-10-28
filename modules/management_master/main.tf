module "launch_vpc" {
  source = "../vpc"

  vpc_cidr = var.vpc_cidr
  public_subnets_map = {
    (var.public_subnet_az) = 1
  }
  private_subnets_map = {}
  subnets_bit_length = var.subnets_bit_length
}


module "launch_management_into_vpc" {
  source = "../management"
  
  vpc_id = module.launch_vpc.vpc_id
  subnet_id = module.launch_vpc.public_subnets_ids_list[0]
  
  // --- EC2 Instance Configuration ---
  management_name = var.management_name
  management_instance_type = var.management_instance_type
  key_name = var.key_name
  allocate_and_associate_eip = var.allocate_and_associate_eip
  volume_size = var.volume_size
  volume_encryption = var.volume_encryption
  enable_instance_connect = var.enable_instance_connect
  disable_instance_termination = var.disable_instance_termination
  metadata_imdsv2_required = var.metadata_imdsv2_required
  instance_tags = var.instance_tags
  
  // --- IAM Permissions ---
  iam_permissions = var.iam_permissions
  predefined_role = var.predefined_role
  sts_roles = var.sts_roles
  
  // --- Check Point Settings ---
  management_version = var.management_version
  admin_shell = var.admin_shell
  management_password_hash = var.management_password_hash
  management_maintenance_mode_password_hash = var.management_maintenance_mode_password_hash
  
  // --- Security Management Server Settings ---
  management_hostname = var.management_hostname
  management_installation_type = var.management_installation_type
  SICKey = var.SICKey
  allow_upload_download = var.allow_upload_download
  gateway_management = var.gateway_management
  admin_cidr = var.admin_cidr
  gateway_addresses = var.gateway_addresses
  primary_ntp = var.primary_ntp
  secondary_ntp = var.secondary_ntp
  management_bootstrap_script = var.management_bootstrap_script
  volume_type = var.volume_type
  is_gwlb_iam = var.is_gwlb_iam
  security_rules = var.security_rules
}
