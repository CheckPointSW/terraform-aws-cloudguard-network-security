output "internal_default_route_ipv4_id" {
  value = length(aws_route.internal_default_route) > 0 ? aws_route.internal_default_route.*.id : null
}
output "internal_default_route_ipv6_id" {
  value = length(aws_route.internal_default_route_ipv6) > 0 ? aws_route.internal_default_route_ipv6.*.id : null
}