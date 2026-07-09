locals {
  ipv6_enabled = var.ip_mode != "IPv4"
  ipv4_enabled = var.ip_mode != "IPv6"

  // AWS Partner Revenue Measurement (PRM) tag, added to revenue-generating resources.
  prm_tags = var.product_code != "" ? { "aws-apn-id" = "pc:${var.product_code}" } : {}
}