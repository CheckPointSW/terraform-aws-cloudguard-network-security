locals {
  internal_route_table_ipv4_condition = var.private_route_table != "" && var.ip_mode != "IPv6" ? 1 : 0
  internal_route_table_ipv6_condition = var.private_route_table != "" && var.ip_mode != "IPv4" ? 1 : 0
}