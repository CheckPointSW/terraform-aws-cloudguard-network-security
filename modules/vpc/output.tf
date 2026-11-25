output "vpc_id" {
  value = aws_vpc.vpc.id
}
output "public_subnets_ids_list" {
  value = [for public_subnet in aws_subnet.public_subnets : public_subnet.id ]
}
output "public_subnets_ids_map" {
  value = { for zone, subnet in aws_subnet.public_subnets : zone => subnet.id }
}
output "private_subnets_ids_list" {
  value = [for private_subnet in aws_subnet.private_subnets : private_subnet.id]
}
output "tgw_subnets_ids_list" {
  value = [for tgw_subnet in aws_subnet.tgw_subnets : tgw_subnet.id]
}
output "public_subnet_rtbs" {
  // Map of availability-zone => public route table id (one route table per AZ)
  value = { for az, rtb in aws_route_table.public_subnet_rtb : az => rtb.id }
}
output "public_rtb" {
  // Deprecated: with per-AZ route tables this returns the first public route table id.
  // Prefer public_subnet_rtbs for per-AZ wiring.
  value = length(aws_route_table.public_subnet_rtb) > 0 ? values(aws_route_table.public_subnet_rtb)[0].id : null
}
output "aws_igw" {
  value = aws_internet_gateway.igw.id
}
output "ip_mode"{
   value = var.ip_mode
}
output "vpc_cidr_block" {
  value = aws_vpc.vpc.cidr_block
}
output "vpc_ipv6_cidr_block" {
  value = try(coalesce(aws_vpc.vpc.ipv6_cidr_block, ""), "")
}
output "public_subnets_cidrs_map" {
  value = { for zone, subnet in aws_subnet.public_subnets : zone => subnet.cidr_block }
}
output "public_subnets_ipv6_cidrs_map" {
  value = { for zone, subnet in aws_subnet.public_subnets : zone => subnet.ipv6_cidr_block }
}
