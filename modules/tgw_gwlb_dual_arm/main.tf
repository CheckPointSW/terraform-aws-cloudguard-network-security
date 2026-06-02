data "aws_vpc" "vpc" {
  id = var.vpc_id
}

locals {
  # Note: For dual-arm solutions, IPv4 is always enabled (IPv4 or DualStack modes)
  ipv6_enabled = var.ip_mode == "DualStack"
}

# Creates the first Gateway Load Balancer Endpoint (GWLBe) subnet
# This subnet hosts the GWLB endpoint which intercepts traffic and forwards it to the security gateways
# Required for implementing centralized security inspection in the first availability zone
resource "aws_subnet" "gwlbe_subnet1" {
  vpc_id = var.vpc_id
  availability_zone = element(var.availability_zones, 0)
  cidr_block = var.gwlbe_subnet_1_cidr
  ipv6_cidr_block = local.ipv6_enabled && data.aws_vpc.vpc.ipv6_cidr_block != "" ? cidrsubnet(data.aws_vpc.vpc.ipv6_cidr_block, 8, 13) : null
  ipv6_native = false
  assign_ipv6_address_on_creation = local.ipv6_enabled && data.aws_vpc.vpc.ipv6_cidr_block != ""
  enable_resource_name_dns_a_record_on_launch    = true
  enable_resource_name_dns_aaaa_record_on_launch = false
  tags = {
    Name = var.deployment_prefix != "" ? "${var.deployment_prefix}-GWLBe subnet 1" : "GWLBe subnet 1"
    Network = "Private"
  }
}


# Creates the second Gateway Load Balancer Endpoint (GWLBe) subnet
# Provides high availability by distributing GWLB endpoints across multiple AZs
# Essential for redundancy and load distribution in security inspection
resource "aws_subnet" "gwlbe_subnet2" {
  vpc_id = var.vpc_id
  availability_zone = element(var.availability_zones, 1)
  cidr_block = var.gwlbe_subnet_2_cidr
  ipv6_cidr_block = local.ipv6_enabled && data.aws_vpc.vpc.ipv6_cidr_block != "" ? cidrsubnet(data.aws_vpc.vpc.ipv6_cidr_block, 8, 23) : null
  ipv6_native = false
  assign_ipv6_address_on_creation = local.ipv6_enabled && data.aws_vpc.vpc.ipv6_cidr_block != ""
  enable_resource_name_dns_a_record_on_launch    = true
  enable_resource_name_dns_aaaa_record_on_launch = false
  tags = {
    Name = var.deployment_prefix != "" ? "${var.deployment_prefix}-GWLBe subnet 2" : "GWLBe subnet 2"
    Network = "Private"
  }
}


# Creates the third Gateway Load Balancer Endpoint (GWLBe) subnet (conditional)
# Only created when 3 or more availability zones are specified
# Extends high availability and load distribution to a third AZ when required
resource "aws_subnet" "gwlbe_subnet3" {
  count = var.number_of_AZs >= 3 ? 1 :0
  vpc_id = var.vpc_id
  availability_zone = element(var.availability_zones, 2)
  cidr_block = var.gwlbe_subnet_3_cidr
  ipv6_cidr_block = local.ipv6_enabled && data.aws_vpc.vpc.ipv6_cidr_block != "" ? cidrsubnet(data.aws_vpc.vpc.ipv6_cidr_block, 8, 33) : null
  ipv6_native = false
  assign_ipv6_address_on_creation = local.ipv6_enabled && data.aws_vpc.vpc.ipv6_cidr_block != ""
  enable_resource_name_dns_a_record_on_launch    = true
  enable_resource_name_dns_aaaa_record_on_launch = false
  tags = {
    Name = var.deployment_prefix != "" ? "${var.deployment_prefix}-GWLBe subnet 3" : "GWLBe subnet 3"
    Network = "Private"
  }
}


# Creates the fourth Gateway Load Balancer Endpoint (GWLBe) subnet (conditional)
# Only created when 4 or more availability zones are specified
# Provides maximum high availability and load distribution across four AZs
resource "aws_subnet" "gwlbe_subnet4" {
  count = var.number_of_AZs >= 4 ? 1 :0
  vpc_id = var.vpc_id
  availability_zone = element(var.availability_zones, 3)
  cidr_block = var.gwlbe_subnet_4_cidr
  ipv6_cidr_block = local.ipv6_enabled && data.aws_vpc.vpc.ipv6_cidr_block != "" ? cidrsubnet(data.aws_vpc.vpc.ipv6_cidr_block, 8, 43) : null
  ipv6_native = false
  assign_ipv6_address_on_creation = local.ipv6_enabled && data.aws_vpc.vpc.ipv6_cidr_block != ""
  enable_resource_name_dns_a_record_on_launch    = true
  enable_resource_name_dns_aaaa_record_on_launch = false
  tags = {
    Name = var.deployment_prefix != "" ? "${var.deployment_prefix}-GWLBe subnet 4" : "GWLBe subnet 4"
    Network = "Private"
  }
}

# Creates the Management subnet
# Dedicated subnet for the Security Management Server deployment
# Isolated from gateway traffic for management security and stability
resource "aws_subnet" "management_subnet" {
  vpc_id = var.vpc_id
  availability_zone = element(var.availability_zones, 0)
  cidr_block = var.management_subnet_cidr
  ipv6_cidr_block = local.ipv6_enabled && data.aws_vpc.vpc.ipv6_cidr_block != "" ? cidrsubnet(data.aws_vpc.vpc.ipv6_cidr_block, 8, 253) : null
  ipv6_native = false
  assign_ipv6_address_on_creation = local.ipv6_enabled && data.aws_vpc.vpc.ipv6_cidr_block != ""
  enable_resource_name_dns_a_record_on_launch    = true
  enable_resource_name_dns_aaaa_record_on_launch = false
  map_public_ip_on_launch = true
  tags = {
    Name = var.deployment_prefix != "" ? "${var.deployment_prefix}-Management subnet" : "Management subnet"
    Network = "Public"
  }
}

# Route table for Private Subnets
# This route table is dedicated to private subnets, separate from GWLBe subnets
resource "aws_route_table" "private_subnets_rtb" {
  vpc_id = var.vpc_id
  tags = {
    Name = "Private Subnets Route Table"
    Network = "Private"
  }
}

# Associates private subnets with their dedicated route table
resource "aws_route_table_association" "private_subnets_rtb_assoc" {
  count = length(var.gateways_private_subnets)
  subnet_id      = var.gateways_private_subnets[count.index]
  route_table_id = aws_route_table.private_subnets_rtb.id
}

# Route table for GWLBe Subnets
# This route table is dedicated to GWLB endpoint subnets, separate from private subnets
resource "aws_route_table" "gwlbe_subnets_rtb" {
  vpc_id = var.vpc_id
  tags = {
    Name = "GWLBe Subnets Route Table"
    Network = "Private"
  }
}

# Associates GWLBe subnet 1 with the dedicated GWLBe route table
resource "aws_route_table_association" "gwlbe_subnet1_rtb_assoc" {
  subnet_id      = aws_subnet.gwlbe_subnet1.id
  route_table_id = aws_route_table.gwlbe_subnets_rtb.id
}

# Associates GWLBe subnet 2 with the dedicated GWLBe route table
resource "aws_route_table_association" "gwlbe_subnet2_rtb_assoc" {
  subnet_id      = aws_subnet.gwlbe_subnet2.id
  route_table_id = aws_route_table.gwlbe_subnets_rtb.id
}

# Associates GWLBe subnet 3 with the dedicated GWLBe route table (conditional)
resource "aws_route_table_association" "gwlbe_subnet3_rtb_assoc" {
  count = var.number_of_AZs >= 3 ? 1 : 0
  subnet_id      = aws_subnet.gwlbe_subnet3[0].id
  route_table_id = aws_route_table.gwlbe_subnets_rtb.id
}

# Associates GWLBe subnet 4 with the dedicated GWLBe route table (conditional)
resource "aws_route_table_association" "gwlbe_subnet4_rtb_assoc" {
  count = var.number_of_AZs >= 4 ? 1 : 0
  subnet_id      = aws_subnet.gwlbe_subnet4[0].id
  route_table_id = aws_route_table.gwlbe_subnets_rtb.id
}

# Route table for Management Subnet
# Routes management traffic directly to Internet Gateway for external access
resource "aws_route_table" "management_subnet_rtb" {
  vpc_id = var.vpc_id
  tags = {
    Name = "Management Subnet Route Table"
    Network = "Public"
  }
}

# Default route to Internet Gateway for management subnet
resource "aws_route" "management_igw_route" {
  route_table_id = aws_route_table.management_subnet_rtb.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = var.internet_gateway_id
}

# IPv6 default route to Internet Gateway for management subnet
resource "aws_route" "management_igw_route_ipv6" {
  count = local.ipv6_enabled ? 1 : 0
  route_table_id = aws_route_table.management_subnet_rtb.id
  destination_ipv6_cidr_block = "::/0"
  gateway_id = var.internet_gateway_id
}

# Associates management subnet with its route table
resource "aws_route_table_association" "management_subnet_rtb_assoc" {
  subnet_id      = aws_subnet.management_subnet.id
  route_table_id = aws_route_table.management_subnet_rtb.id
}


module "gwlb" {
  source = "../gwlb_dual_arm"
  
  vpc_id = var.vpc_id
  gateways_private_subnets = var.gateways_private_subnets
  gateways_public_subnets = var.gateways_public_subnets
  management_subnet = aws_subnet.management_subnet.id

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
  connection_acceptance_required = false
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
  existing_security_group_id = var.existing_security_group_id
}

# Creates the first Gateway Load Balancer VPC Endpoint
# This endpoint intercepts traffic in the first AZ and forwards it to the GWLB for security inspection
# Essential for the traffic flow redirection mechanism in distributed security architecture
resource "aws_vpc_endpoint" "gwlb_endpoint1" {
  depends_on = [module.gwlb, aws_subnet.gwlbe_subnet1]
  vpc_id = var.vpc_id
  vpc_endpoint_type = "GatewayLoadBalancer"
  service_name = module.gwlb.gwlb_service_name
  subnet_ids = aws_subnet.gwlbe_subnet1[*].id
  ip_address_type = var.ip_mode == "DualStack" ? "dualstack" : "ipv4"
  tags = {
    "Name" = "gwlb_endpoint1"
  }
}
# Creates the second Gateway Load Balancer VPC Endpoint
# Provides high availability and load distribution for traffic inspection in the second AZ
# Works in conjunction with the first endpoint to ensure redundant security inspection
resource "aws_vpc_endpoint" "gwlb_endpoint2" {
  depends_on = [module.gwlb, aws_subnet.gwlbe_subnet2]
  vpc_id = var.vpc_id
  vpc_endpoint_type = "GatewayLoadBalancer"
  service_name = module.gwlb.gwlb_service_name
  subnet_ids = aws_subnet.gwlbe_subnet2[*].id
  ip_address_type = var.ip_mode == "DualStack" ? "dualstack" : "ipv4"
  tags = {
    "Name" = "gwlb_endpoint2"
  }
}
# Creates the third Gateway Load Balancer VPC Endpoint (conditional)
# Only created when 3 or more AZs are specified to extend security inspection to the third AZ
# Maintains consistent security posture across all deployed availability zones
resource "aws_vpc_endpoint" "gwlb_endpoint3" {
  count = var.number_of_AZs >= 3 ? 1 :0
  depends_on = [module.gwlb, aws_subnet.gwlbe_subnet3]
  vpc_id = var.vpc_id
  vpc_endpoint_type = "GatewayLoadBalancer"
  service_name = module.gwlb.gwlb_service_name
  subnet_ids = aws_subnet.gwlbe_subnet3[*].id
  ip_address_type = var.ip_mode == "DualStack" ? "dualstack" : "ipv4"
  tags = {
    "Name" = "gwlb_endpoint3"
  }
}
# Creates the fourth Gateway Load Balancer VPC Endpoint (conditional)
# Only created when 4 or more AZs are specified for maximum availability security inspection
# Completes the GWLB endpoint coverage across all four availability zones
resource "aws_vpc_endpoint" "gwlb_endpoint4" {
  count = var.number_of_AZs >= 4 ? 1 :0
  depends_on = [module.gwlb, aws_subnet.gwlbe_subnet4]
  vpc_id = var.vpc_id
  vpc_endpoint_type = "GatewayLoadBalancer"
  service_name = module.gwlb.gwlb_service_name
  subnet_ids = aws_subnet.gwlbe_subnet4[*].id
  ip_address_type = var.ip_mode == "DualStack" ? "dualstack" : "ipv4"
  tags = {
    "Name" = "gwlb_endpoint4"
  }
}

# Route table for Transit Gateway attachment subnet 1 - redirects traffic through GWLB endpoint
# All traffic from TGW attachment subnet is routed through the GWLB endpoint for security inspection
# This is the key mechanism that ensures all north-south traffic gets inspected by security gateways
resource "aws_route_table" "tgw_attachment_subnet1_rtb" {
  vpc_id = var.vpc_id
  route {
    cidr_block = "0.0.0.0/0"
    vpc_endpoint_id = aws_vpc_endpoint.gwlb_endpoint1.id
  }
  dynamic "route" {
    for_each = local.ipv6_enabled ? [1] : []
    content {
      ipv6_cidr_block = "::/0"
      vpc_endpoint_id = aws_vpc_endpoint.gwlb_endpoint1.id
    }
  }
  tags = {
    Name = "TGW Attachment Subnet 1 Route Table"
    Network = "Private"
  }
}
# Associates the TGW attachment subnet 1 with its route table
# Links the first TGW attachment subnet to force traffic through the GWLB endpoint
resource "aws_route_table_association" "tgw_attachment1_rtb_assoc" {
  subnet_id      = var.transit_gateway_attachment_subnet_1_id
  route_table_id = aws_route_table.tgw_attachment_subnet1_rtb.id
}
# Route table for Transit Gateway attachment subnet 2 - redirects traffic through GWLB endpoint
# Ensures traffic from the second TGW attachment subnet is also inspected for security
# Maintains consistent security policy enforcement across all availability zones
resource "aws_route_table" "tgw_attachment_subnet2_rtb" {
  vpc_id = var.vpc_id
  route {
    cidr_block = "0.0.0.0/0"
    vpc_endpoint_id = aws_vpc_endpoint.gwlb_endpoint2.id
  }
  dynamic "route" {
    for_each = local.ipv6_enabled ? [1] : []
    content {
      ipv6_cidr_block = "::/0"
      vpc_endpoint_id = aws_vpc_endpoint.gwlb_endpoint2.id
    }
  }
  tags = {
    Name = "TGW Attachment Subnet 2 Route Table"
    Network = "Private"
  }
}
# Associates the TGW attachment subnet 2 with its route table
# Links the second TGW attachment subnet to ensure traffic inspection through GWLB
resource "aws_route_table_association" "tgw_attachment2_rtb_assoc" {
  subnet_id      = var.transit_gateway_attachment_subnet_2_id
  route_table_id = aws_route_table.tgw_attachment_subnet2_rtb.id
}
# Route table for Transit Gateway attachment subnet 3 (conditional) - redirects traffic through GWLB endpoint
# Only created when 3+ AZs are used to extend security inspection to the third availability zone
# Maintains comprehensive security coverage across all deployed AZs
resource "aws_route_table" "tgw_attachment_subnet3_rtb" {
  count = var.number_of_AZs >= 3 ? 1 :0
  vpc_id = var.vpc_id
  route {
    cidr_block = "0.0.0.0/0"
    vpc_endpoint_id = aws_vpc_endpoint.gwlb_endpoint3[0].id
  }
  dynamic "route" {
    for_each = local.ipv6_enabled ? [1] : []
    content {
      ipv6_cidr_block = "::/0"
      vpc_endpoint_id = aws_vpc_endpoint.gwlb_endpoint3[0].id
    }
  }
  tags = {
    Name = "TGW Attachment Subnet 3 Route Table"
    Network = "Private"
  }
}
# Associates the TGW attachment subnet 3 with its route table (conditional)
# Links the third TGW attachment subnet to its GWLB endpoint route table when deployed
resource "aws_route_table_association" "tgw_attachment3_rtb_assoc" {
  count = var.number_of_AZs >= 3 ? 1 :0
  subnet_id      = var.transit_gateway_attachment_subnet_3_id
  route_table_id = aws_route_table.tgw_attachment_subnet3_rtb[0].id
}
# Route table for Transit Gateway attachment subnet 4 (conditional) - redirects traffic through GWLB endpoint
# Only created when 4+ AZs are used for maximum availability security inspection
# Completes the security coverage across all four availability zones
resource "aws_route_table" "tgw_attachment_subnet4_rtb" {
  count = var.number_of_AZs >= 4 ? 1 :0
  vpc_id = var.vpc_id
  route {
    cidr_block = "0.0.0.0/0"
    vpc_endpoint_id = aws_vpc_endpoint.gwlb_endpoint4[0].id
  }
  dynamic "route" {
    for_each = local.ipv6_enabled ? [1] : []
    content {
      ipv6_cidr_block = "::/0"
      vpc_endpoint_id = aws_vpc_endpoint.gwlb_endpoint4[0].id
    }
  }
  tags = {
    Name = "TGW Attachment Subnet 4 Route Table"
    Network = "Private"
  }
}
# Associates the TGW attachment subnet 4 with its route table (conditional)
# Links the fourth TGW attachment subnet to its GWLB endpoint route table for complete coverage
resource "aws_route_table_association" "tgw_attachment4_rtb_assoc" {
  count = var.number_of_AZs >= 4 ? 1 :0
  subnet_id      = var.transit_gateway_attachment_subnet_4_id
  route_table_id = aws_route_table.tgw_attachment_subnet4_rtb[0].id
}