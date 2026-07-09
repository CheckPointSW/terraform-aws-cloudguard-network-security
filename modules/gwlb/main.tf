

// Resolve the AWS Marketplace product code from the gateway version/license so the
// GWLB and endpoint service can be PRM-tagged for revenue attribution.
module "amis" {
  source = "../amis"

  version_license = var.gateway_version
}

module "gateway_load_balancer" {
  source = "../load_balancer"

  load_balancers_type = "gateway"
  instances_subnets = var.subnet_ids
  prefix_name = var.gateway_load_balancer_name
  internal = true

  security_groups = []
  tags = {
    x-chkp-management = var.management_server
    x-chkp-template = var.configuration_template
    aws-apn-id = "pc:${module.amis.product_code}"
  }
  vpc_id = var.vpc_id
  load_balancer_protocol = "GENEVE"
  target_group_port = 6081
  listener_port = 6081
  cross_zone_load_balancing = var.enable_cross_zone_load_balancing
  ip_mode = var.ip_mode

  // default tcp timeout 1 hour
  tcp_idle_timeout = 3600
}

resource "aws_vpc_endpoint_service" "gwlb_endpoint_service" {
depends_on = [module.gateway_load_balancer]
  gateway_load_balancer_arns = module.gateway_load_balancer[*].load_balancer_arn
  acceptance_required        = var.connection_acceptance_required
  supported_ip_address_types = var.ip_mode != "IPv4" ? ["ipv4", "ipv6"] : ["ipv4"]
  tags = {
    "Name" = "gwlb-endpoint-service-${var.gateway_load_balancer_name}"
    aws-apn-id = "pc:${module.amis.product_code}"
  }
}

module "autoscale_gwlb" {
  source = "../autoscale_gwlb"
  depends_on = [module.gateway_load_balancer]

  target_groups = module.gateway_load_balancer[*].target_group_arn
  vpc_id = var.vpc_id
  subnet_ids = var.subnet_ids
  gateway_name = var.gateway_name
  gateway_instance_type = var.gateway_instance_type
  key_name = var.key_name
  enable_volume_encryption = var.enable_volume_encryption
  enable_instance_connect = var.enable_instance_connect
  metadata_imdsv2_required = var.metadata_imdsv2_required
  minimum_group_size = var.minimum_group_size
  maximum_group_size = var.maximum_group_size
  gateway_version = var.gateway_version
  gateway_password_hash = var.gateway_password_hash
  gateway_maintenance_mode_password_hash = var.gateway_maintenance_mode_password_hash
  gateway_SICKey = var.gateway_SICKey
  allow_upload_download = var.allow_upload_download
  enable_cloudwatch = var.enable_cloudwatch
  gateway_bootstrap_script = var.gateway_bootstrap_script
  admin_shell = var.admin_shell
  gateways_provision_address_type = var.gateways_provision_address_type
  allocate_public_IP = var.allocate_public_IP
  management_server = var.management_server
  configuration_template = var.configuration_template
  volume_type = var.volume_type
  ip_mode = var.ip_mode
  existing_security_group_id = var.existing_security_group_id
}

data "aws_region" "current"{}

module "management" {
  count = local.deploy_management_condition ? 1 : 0
  source = "../management"

  vpc_id = var.vpc_id
  subnet_id = var.subnet_ids[0]
  management_name = var.management_server
  management_instance_type = var.management_instance_type
  key_name = var.key_name
  allocate_and_associate_eip = true
  volume_encryption = var.enable_volume_encryption ? "alias/aws/ebs" : ""
  enable_instance_connect = var.enable_instance_connect
  disable_instance_termination = var.disable_instance_termination
  metadata_imdsv2_required = var.metadata_imdsv2_required
  management_version = var.management_version
  management_password_hash = var.management_password_hash
  management_maintenance_mode_password_hash = var.management_maintenance_mode_password_hash
  allow_upload_download = var.allow_upload_download
  admin_cidr = var.admin_cidr
  admin_shell = var.admin_shell
  gateway_addresses = var.gateways_addresses
  gateway_management = var.gateway_management
  management_bootstrap_script = templatefile("${path.module}/gwlb_mgmt_bootstrap.tftpl", {
    ManagementServer      = var.management_server
    ConfigurationTemplate = var.configuration_template
    GatewaysPolicy        = var.gateways_policy
    SICKey                = var.gateway_SICKey
    Region                = data.aws_region.current.name
    GatewayVersion        = split("-", var.gateway_version)[0]
  })
  volume_type = var.volume_type
  is_gwlb = true
}
