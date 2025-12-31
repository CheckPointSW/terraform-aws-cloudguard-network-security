locals {
  ipv6_enabled = var.ip_mode != "IPv4"
  ipv4_enabled = var.ip_mode != "IPv6"
}