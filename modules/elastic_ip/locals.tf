locals {
  allocate_and_associate_eip_condition = var.allocate_and_associate_eip == true && var.ip_mode != "IPv6" ? 1 : 0
}