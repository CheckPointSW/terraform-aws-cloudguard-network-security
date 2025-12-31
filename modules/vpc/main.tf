// --- VPC ---
resource "aws_vpc" "vpc" {
  cidr_block = var.vpc_cidr
  assign_generated_ipv6_cidr_block = local.ipv6_enabled
}

// --- Internet Gateway ---
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
}

// --- Public Subnets ---
resource "aws_subnet" "public_subnets" {
  for_each = var.public_subnets_map

  vpc_id = aws_vpc.vpc.id
  availability_zone = each.key

  # IPv6 Support
  cidr_block = !local.ipv4_enabled ? null : cidrsubnet(aws_vpc.vpc.cidr_block, var.subnets_bit_length, each.value)
  ipv6_cidr_block = local.ipv6_enabled ? cidrsubnet(aws_vpc.vpc.ipv6_cidr_block, var.subnets_bit_length, each.value) : null
  ipv6_native = !local.ipv4_enabled
  assign_ipv6_address_on_creation = local.ipv6_enabled
  map_public_ip_on_launch = !local.ipv4_enabled ? null : true
  enable_resource_name_dns_a_record_on_launch    = local.ipv4_enabled
  enable_resource_name_dns_aaaa_record_on_launch = !local.ipv4_enabled

  tags = {
    Name = format("Public subnet %s", each.value)
  }
}

// --- Private Subnets ---
resource "aws_subnet" "private_subnets" {
  for_each = var.private_subnets_map

  vpc_id = aws_vpc.vpc.id
  availability_zone = each.key

  # IPv6 Support
  cidr_block = !local.ipv4_enabled ? null : cidrsubnet(aws_vpc.vpc.cidr_block, var.subnets_bit_length, each.value)
  ipv6_cidr_block = local.ipv6_enabled ? cidrsubnet(aws_vpc.vpc.ipv6_cidr_block, var.subnets_bit_length, each.value) : null
  ipv6_native = !local.ipv4_enabled
  assign_ipv6_address_on_creation = local.ipv6_enabled
  enable_resource_name_dns_a_record_on_launch    = local.ipv4_enabled
  enable_resource_name_dns_aaaa_record_on_launch = !local.ipv4_enabled

  tags = {
    Name = format("Private subnet %s", each.value)
  }
}

// --- tgw Subnets ---
resource "aws_subnet" "tgw_subnets" {
  for_each = var.tgw_subnets_map

  vpc_id = aws_vpc.vpc.id
  availability_zone = each.key

  # IPv6 Support
  cidr_block = !local.ipv4_enabled ? null : cidrsubnet(aws_vpc.vpc.cidr_block, var.subnets_bit_length, each.value)
  ipv6_cidr_block = local.ipv6_enabled ? cidrsubnet(aws_vpc.vpc.ipv6_cidr_block, var.subnets_bit_length, each.value) : null
  ipv6_native = !local.ipv4_enabled
  assign_ipv6_address_on_creation = local.ipv6_enabled
  enable_resource_name_dns_a_record_on_launch    = local.ipv4_enabled
  enable_resource_name_dns_aaaa_record_on_launch = !local.ipv4_enabled

  tags = {
    Name = format("tgw subnet %s", each.value)
  }
}


// --- Routes ---
resource "aws_route_table" "public_subnet_rtb" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "Public Subnets Route Table"
  }
}
resource "aws_route" "vpc_internet_access" {
  count = local.ipv4_enabled ? 1 : 0
  route_table_id = aws_route_table.public_subnet_rtb.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.igw.id
}
resource "aws_route" "vpc_internet_access_ipv6" {
  count = local.ipv6_enabled ? 1 : 0
  route_table_id = aws_route_table.public_subnet_rtb.id
  destination_ipv6_cidr_block = "::/0"
  gateway_id = aws_internet_gateway.igw.id
}
resource "aws_route_table_association" "public_rtb_to_public_subnets" {
  for_each = aws_subnet.public_subnets
  route_table_id = aws_route_table.public_subnet_rtb.id
  subnet_id = each.value.id
}

