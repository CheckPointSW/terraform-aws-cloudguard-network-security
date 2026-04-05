output "ami_id" {
  value = module.amis.ami_id
}
output "availability_zone" {
  value = data.aws_subnet.public_subnet.availability_zone
}
output "region" {
  value = data.aws_region.current.name
}
output "zone_type" {
  value = coalesce(try(data.aws_availability_zone.subnet_az.zone_type, null), "availability-zone")
}
output "network_border_group" {
  value = coalesce(try(data.aws_availability_zone.subnet_az.network_border_group, null), data.aws_region.current.name)
}
output "cluster_public_ip" {
  value = var.allocate_and_associate_eip ? aws_eip.cluster_eip.*.public_ip : []
}
output "member_a_public_ip" {
  value = aws_eip.member_a_eip.*.public_ip
}
output "member_b_public_ip" {
  value = aws_eip.member_b_eip.*.public_ip
}
output "member_a_ssh" {
  value = var.allocate_and_associate_eip ? format("ssh -i %s admin@%s", var.key_name, aws_eip.member_a_eip[0].public_ip) : ""
}
output "member_b_ssh" {
  value = var.allocate_and_associate_eip ? format("ssh -i %s admin@%s", var.key_name, aws_eip.member_b_eip[0].public_ip) : ""
}
output "member_a_url" {
  value = var.allocate_and_associate_eip ? format("https://%s", aws_eip.member_a_eip[0].public_ip) : ""
}
output "member_b_url" {
  value = var.allocate_and_associate_eip ? format("https://%s", aws_eip.member_b_eip[0].public_ip) : ""
}