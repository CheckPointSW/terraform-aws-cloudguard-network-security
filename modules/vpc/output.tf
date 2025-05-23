output "vpc_id" {
  value = aws_vpc.vpc.id
}
output "public_subnets_ids_list" {
  value = [for public_subnet in aws_subnet.public_subnets : public_subnet.id ]
}
output "private_subnets_ids_list" {
  value = [for private_subnet in aws_subnet.private_subnets : private_subnet.id]
}
output "tgw_subnets_ids_list" {
  value = [for tgw_subnet in aws_subnet.tgw_subnets : tgw_subnet.id]
}
output "public_rtb" {
  value = aws_route_table.public_subnet_rtb.id
}
output "aws_igw" {
  value = aws_internet_gateway.igw.id
}
output "enable_ipv6"{
   value = aws_vpc.vpc.assign_generated_ipv6_cidr_block
}