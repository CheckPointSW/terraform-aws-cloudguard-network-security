module "launch_vpc" {
  source = "../vpc"

  vpc_cidr = var.vpc_cidr
  public_subnets_map = {
    (var.public_subnet_az) = 1
  }
  private_subnets_map = {}
  subnets_bit_length = var.subnets_bit_length
}

module "launch_mds_into_vpc" {
  source = "../mds"

  vpc_id = module.launch_vpc.vpc_id
  subnet_id = module.launch_vpc.public_subnets_ids_list[0]

  // --- EC2 Instance Configuration ---
  mds_name = var.mds_name
  mds_instance_type = var.mds_instance_type
  key_name = var.key_name
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
  mds_version = var.mds_version
  mds_admin_shell = var.mds_admin_shell
  mds_password_hash = var.mds_password_hash
  mds_maintenance_mode_password_hash = var.mds_maintenance_mode_password_hash

  // --- Multi-Domain Server Settings ---
  mds_hostname = var.mds_hostname
  mds_installation_type = var.mds_installation_type
  mds_SICKey = var.mds_SICKey
  allow_upload_download = var.allow_upload_download
  admin_cidr = var.admin_cidr
  gateway_addresses = var.gateway_addresses
  primary_ntp = var.primary_ntp
  secondary_ntp = var.secondary_ntp
  mds_bootstrap_script = var.mds_bootstrap_script

  // --- Security Rules ---
  security_rules = var.security_rules
}
