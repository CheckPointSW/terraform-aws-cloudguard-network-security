resource "aws_security_group" "permissive_sg" {
  description = "Permissive security group"
  vpc_id = var.vpc_id
  name_prefix = format("%s-PermissiveSecurityGroup", var.resources_tag_name != "" ? var.resources_tag_name : var.gateway_name) // Group name
  tags = {
    Name = format("%s-PermissiveSecurityGroup", var.resources_tag_name != "" ? var.resources_tag_name : var.gateway_name) // Resource name
  }
}
# IPv4 ingress rules
resource "aws_vpc_security_group_ingress_rule" "ingress_rule_ipv4_custom" {
  for_each = { for idx, rule in var.security_rules : idx => rule if rule.direction == "ingress" && var.ip_mode != "IPv6" }
  
  security_group_id = aws_security_group.permissive_sg.id
  cidr_ipv4         = each.value.cidr_blocks[0]  # Assuming first CIDR is IPv4
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  ip_protocol       = each.value.protocol
}
resource "aws_vpc_security_group_ingress_rule" "ingress_rule_ipv4_default" {
  count = length([for rule in var.security_rules : rule if rule.direction == "ingress"]) == 0 && var.ip_mode != "IPv6" ? 1 : 0
  
  security_group_id = aws_security_group.permissive_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 0
  to_port           = 0
  ip_protocol       = "-1"
}
# IPv4 egress rules
resource "aws_vpc_security_group_egress_rule" "egress_rule_ipv4_custom" {
  for_each = { for idx, rule in var.security_rules : idx => rule if rule.direction == "egress" && var.ip_mode != "IPv6" }
  
  security_group_id = aws_security_group.permissive_sg.id
  cidr_ipv4         = each.value.cidr_blocks[0]  # Assuming first CIDR is IPv4
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  ip_protocol       = each.value.protocol
}
resource "aws_vpc_security_group_egress_rule" "egress_rule_ipv4_default" {
  count = length([for rule in var.security_rules : rule if rule.direction == "egress"]) == 0 && var.ip_mode != "IPv6" ? 1 : 0
  
  security_group_id = aws_security_group.permissive_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 0
  to_port           = 0
  ip_protocol       = "-1"
}
# IPv6 ingress rules
resource "aws_vpc_security_group_ingress_rule" "ingress_rule_ipv6_default" {
  count = var.ip_mode != "IPv4" && length([for rule in var.security_rules : rule if rule.direction == "ingress"]) == 0 ? 1 : 0
  
  security_group_id = aws_security_group.permissive_sg.id
  cidr_ipv6         = "::/0"
  from_port         = 0
  to_port           = 0
  ip_protocol       = "-1"
}
# IPv6 egress rules
resource "aws_vpc_security_group_egress_rule" "egress_rule_ipv6_default" {
  count = var.ip_mode != "IPv4" && length([for rule in var.security_rules : rule if rule.direction == "egress"]) == 0 ? 1 : 0
  
  security_group_id = aws_security_group.permissive_sg.id
  cidr_ipv6         = "::/0"
  from_port         = 0
  to_port           = 0
  ip_protocol       = "-1"
}