resource "aws_route" "internal_default_route" {
  count = local.internal_route_table_ipv4_condition
  route_table_id = var.private_route_table
  destination_cidr_block = "0.0.0.0/0"
  network_interface_id = var.internal_eni_id
}
# IPv6 default route (only when IPv6 is enabled)
resource "aws_route" "internal_default_route_ipv6" {
  count = local.internal_route_table_ipv6_condition
  route_table_id = var.private_route_table
  destination_ipv6_cidr_block = "::/0"
  network_interface_id = var.internal_eni_id
}