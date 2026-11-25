variable "create_asg_per_az" {
  type        = bool
  description = "False (default) creates one ASG across selected AZs and requires an empty az_instance_types map. True requires gateway_instance_type to be omitted or null and a nonempty instance type in each map entry. It creates one ASG per map entry and, unless an existing IAM instance profile is supplied, a shared gateway IAM role/profile; an empty map creates no ASGs but retains the selected IAM behavior. When used through gwlb_master, public-subnet routing is unchanged: one route table and association per configured subnet, with default routes when enabled, in either ASG mode. The launch template is always created."
  default     = false
}

variable "az_instance_types" {
  type = map(object({
    subnet_id     = string
    instance_type = string
  }))
  description = "Gateway groups keyed by AZ with subnet_id and instance_type. Each group starts at minimum_group_size and scales up to maximum_group_size. Only valid with create_asg_per_az=true. Each instance_type must be nonempty; gateway_instance_type must be omitted or null."
  default     = {}
  nullable    = false

  validation {
    condition     = alltrue([for v in values(var.az_instance_types) : try(length(trimspace(v.instance_type)) > 0, false)])
    error_message = "Each az_instance_types entry must provide a nonempty instance_type; there is no gateway_instance_type fallback."
  }

  validation {
    condition     = alltrue([for k, v in var.az_instance_types : can(regex("^subnet-[0-9a-f]{8,17}$", v.subnet_id))])
    error_message = "Each az_instance_types entry must name a subnet id (subnet-<hex>)."
  }
}

resource "aws_autoscaling_policy" "az_scale_in" {
  for_each               = local.per_az_groups
  name                   = "${aws_autoscaling_group.az[each.key].name}-scale-in"
  autoscaling_group_name = aws_autoscaling_group.az[each.key].name
  adjustment_type        = "ChangeInCapacity"
  policy_type            = "SimpleScaling"
  scaling_adjustment     = -1
  cooldown               = 300
}

resource "aws_cloudwatch_metric_alarm" "az_scale_in" {
  for_each            = local.per_az_groups
  alarm_name          = "${aws_autoscaling_group.az[each.key].name}-scale-in"
  alarm_description   = "Scale-down if CPU < ${var.scale_in_cpu_threshold}% for 10 minutes"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 2
  tags                = var.custom_tags
  treat_missing_data  = "missing"
  threshold           = var.scale_in_cpu_threshold
  comparison_operator = "LessThanThreshold"
  dimensions          = { AutoScalingGroupName = aws_autoscaling_group.az[each.key].name }
  alarm_actions       = [aws_autoscaling_policy.az_scale_in[each.key].arn]

  lifecycle {
    precondition {
      condition     = var.scale_in_cpu_threshold < var.scale_out_cpu_threshold
      error_message = "scale_in_cpu_threshold (${var.scale_in_cpu_threshold}) must be lower than scale_out_cpu_threshold (${var.scale_out_cpu_threshold}). Keep it at least 20 points lower to avoid flapping."
    }
  }
}

resource "aws_autoscaling_policy" "az_scale_out" {
  for_each               = local.per_az_groups
  name                   = "${aws_autoscaling_group.az[each.key].name}-scale-out"
  autoscaling_group_name = aws_autoscaling_group.az[each.key].name
  adjustment_type        = "ChangeInCapacity"
  policy_type            = "SimpleScaling"
  scaling_adjustment     = 1
  cooldown               = var.scale_out_cooldown
}

resource "aws_cloudwatch_metric_alarm" "az_scale_out" {
  for_each            = local.per_az_groups
  alarm_name          = "${aws_autoscaling_group.az[each.key].name}-scale-out"
  alarm_description   = "Scale-up if CPU > ${var.scale_out_cpu_threshold}% for 10 minutes"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 2
  tags                = var.custom_tags
  treat_missing_data  = "missing"
  threshold           = var.scale_out_cpu_threshold
  comparison_operator = "GreaterThanThreshold"
  dimensions          = { AutoScalingGroupName = aws_autoscaling_group.az[each.key].name }
  alarm_actions       = [aws_autoscaling_policy.az_scale_out[each.key].arn]
}

module "validate_az_instance_type" {
  source   = "../instance_type"
  for_each = local.per_az_groups

  chkp_type     = "gateway"
  instance_type = each.value.instance_type
}
