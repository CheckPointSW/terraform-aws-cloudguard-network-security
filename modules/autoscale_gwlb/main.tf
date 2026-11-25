
module "amis" {
  source = "../amis"
  version_license = var.gateway_version
  custom_ami = var.custom_ami

}

resource "aws_security_group" "permissive_sg" {
  count = local.create_permissive_sg
  name_prefix = format("%s_PermissiveSecurityGroup", local.asg_name)
  description = "Permissive security group"
  vpc_id = var.vpc_id

  dynamic "ingress" {
    for_each = [for rule in var.security_rules : rule if rule.direction == "ingress"]
    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks =  local.ipv4_enabled ? [for cidr in ingress.value.cidr_blocks : cidr if strcontains(cidr, ".")] : []
      ipv6_cidr_blocks = local.ipv6_enabled ? [for cidr in ingress.value.cidr_blocks : cidr if strcontains(cidr, ":")] : []
    }
  }

  dynamic ingress {
    for_each = length([for rule in var.security_rules : rule if rule.direction == "ingress"]) == 0 ? [1] : []
    content{
        from_port    = 0
        to_port      = 0
        protocol     = "-1"
        cidr_blocks  = local.ipv4_enabled ? ["0.0.0.0/0"] : []
        ipv6_cidr_blocks = local.ipv6_enabled ? ["::/0"] : []
    }
  }

  dynamic "egress" {
    for_each = [for rule in var.security_rules : rule if rule.direction == "egress"]
    content {
      from_port   = egress.value.from_port
      to_port     = egress.value.to_port
      protocol    = egress.value.protocol
      cidr_blocks =  local.ipv4_enabled ? [for cidr in egress.value.cidr_blocks : cidr if strcontains(cidr, ".")] : []
      ipv6_cidr_blocks = local.ipv6_enabled ? [for cidr in egress.value.cidr_blocks : cidr if strcontains(cidr, ":")] : []
    }
  }

  dynamic egress {
    for_each = length([for rule in var.security_rules : rule if rule.direction == "egress"]) == 0 ? [1] : []
    content{
        from_port    = 0
        to_port      = 0
        protocol     = "-1"
        cidr_blocks  = local.ipv4_enabled ? ["0.0.0.0/0"] : []
        ipv6_cidr_blocks = local.ipv6_enabled ? ["::/0"] : []
    }
  }
  tags = merge(var.custom_tags, {
    Name = format("%s_PermissiveSecurityGroup", local.asg_name)
    aws-apn-id = "pc:${module.amis.product_code}"
  })
}

resource "aws_launch_template" "asg_launch_template" {
  lifecycle {
    precondition {
      condition     = var.create_asg_per_az || length(var.az_instance_types) == 0
      error_message = "az_instance_types requires create_asg_per_az=true. Otherwise, leave the map empty and use gateway_instance_type."
    }
    precondition {
      condition     = !var.create_asg_per_az || var.gateway_instance_type == null
      error_message = "gateway_instance_type cannot be used when create_asg_per_az=true. Omit it or set it to null, and provide an instance type for each AZ in az_instance_types."
    }
  }

  name        = var.resource_name_base != "" ? coalesce(var.gateway_name, var.resource_name_base) : null
  name_prefix = var.resource_name_base != "" ? null : local.asg_name
  image_id = module.amis.ami_id
  instance_type = var.create_asg_per_az ? null : coalesce(var.gateway_instance_type, "c6in.xlarge")
  key_name = var.key_name
  network_interfaces {
    associate_public_ip_address = var.allocate_public_IP
    security_groups = local.launch_template_security_group_ids
  }
  metadata_options {
    http_tokens = var.metadata_imdsv2_required ? "required" : "optional"
    http_protocol_ipv6 = local.ipv6_enabled ? "enabled" : "disabled"
  }

  dynamic "iam_instance_profile" {
    for_each = var.existing_iam_instance_profile_name != "" || local.create_iam_role == 1 ? [1] : []
    content {
      name = local.instance_profile_name
    }
  }

  monitoring {
    enabled = true
  }

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_type = var.volume_type
      volume_size = var.volume_size
      encrypted   = var.enable_volume_encryption
    }
  }

  description = "Initial template version"
  tags        = length(var.custom_tags) > 0 ? var.custom_tags : null

  // PRM revenue-attribution tag and custom tags on volumes and network interfaces
  // created at launch (instances are tagged via the ASG tag block below with
  // propagate_at_launch). Fires when there is a PRM tag and/or custom tags to set.
  dynamic "tag_specifications" {
    for_each = module.amis.product_code != "" || length(var.custom_tags) > 0 ? toset(["volume", "network-interface"]) : toset([])
    content {
      resource_type = tag_specifications.value
      tags = merge(
        var.custom_tags,
        module.amis.product_code != "" ? { aws-apn-id = "pc:${module.amis.product_code}" } : {}
      )
    }
  }

  user_data = base64encode(templatefile("${path.module}/asg_userdata.yaml", {
    // script's arguments
    TemplateName = local.template_name,
    PasswordHash = local.gateway_password_hash_base64,
    MaintenanceModePassword = local.maintenance_mode_password_hash_base64,
    EnableCloudWatch = var.enable_cloudwatch,
    EnableInstanceConnect = var.enable_instance_connect,
    Shell = var.admin_shell,
    SICKey = local.gateway_SICkey_base64,
    AllowUploadDownload = var.allow_upload_download,
    BootstrapScript = local.gateway_bootstrap_script64,
    OsVersion = local.version_split
    IPMode = var.ip_mode == "IPv4" ? "false" : "true"
  }))

}
resource "aws_autoscaling_group" "asg" {
  count = local.legacy_asg_count

  name_prefix = local.asg_name
  launch_template {
    id = aws_launch_template.asg_launch_template.id
    version = aws_launch_template.asg_launch_template.latest_version
  }
  min_size = var.minimum_group_size
  max_size = var.maximum_group_size
  target_group_arns = var.target_groups
  vpc_zone_identifier = var.subnet_ids
  health_check_grace_period = 3600
  health_check_type = "ELB"

  dynamic "tag" {
    for_each = merge(local.prm_tags, { Name = format("%s%s", var.prefix != "" ? format("%s-", var.prefix) : "", local.gateway_name) })
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
}

resource "aws_autoscaling_group" "az" {
  for_each = local.per_az_groups

  name                = format("%s-%s", local.asg_name, each.key)
  vpc_zone_identifier = [each.value.subnet_id]

  min_size         = var.minimum_group_size
  max_size         = var.maximum_group_size
  desired_capacity = var.minimum_group_size

  target_group_arns         = var.target_groups
  health_check_grace_period = 3600
  health_check_type         = "ELB"

  mixed_instances_policy {
    launch_template {
      launch_template_specification {
        launch_template_id = aws_launch_template.asg_launch_template.id
        version            = aws_launch_template.asg_launch_template.latest_version
      }
      dynamic "override" {
        for_each = [each.value.instance_type]
        content {
          instance_type = override.value
        }
      }
    }
  }

  // Roll template changes; a single-instance group may temporarily reach zero capacity.
  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = var.minimum_group_size == 1 ? 0 : 50
    }
  }

  enabled_metrics = [
    "GroupMinSize", "GroupMaxSize", "GroupDesiredCapacity",
    "GroupInServiceInstances", "GroupPendingInstances", "GroupStandbyInstances",
    "GroupTerminatingInstances", "GroupTotalInstances",
  ]

  lifecycle {
    precondition {
      condition     = var.minimum_group_size >= 1 && floor(var.minimum_group_size) == var.minimum_group_size
      error_message = "Per-AZ groups require minimum_group_size to be a positive integer."
    }
    ignore_changes = [desired_capacity]
  }

  dynamic "tag" {
    for_each = merge(local.prm_tags, { Name = format("%s-%s", local.asg_name, each.key) })
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
}

data "aws_iam_policy_document" "assume_role_policy_document" {
  version = "2012-10-17"
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
    effect = "Allow"
  }
}

resource "aws_iam_role" "role" {
  count = local.create_iam_role
  name        = local.gateway_iam_role_name
  name_prefix = local.gateway_iam_role_name == null ? format("%s-iam_role", local.asg_name) : null
  description = var.create_asg_per_az ? "Role for Check Point CloudGuard Gateway instances" : null
  tags        = var.create_asg_per_az ? var.custom_tags : null
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy_document.json
  path = "/"
}
module "attach_cloudwatch_policy" {
  source = "../cloudwatch_policy"
  count = local.create_iam_role == 1 && var.enable_cloudwatch ? 1 : 0
  role = aws_iam_role.role[count.index].name
  tag_name = local.asg_name
}
resource "aws_iam_instance_profile" "instance_profile" {
  count = local.create_iam_role
  name        = local.gateway_iam_instance_profile_name
  name_prefix = local.gateway_iam_instance_profile_name == null ? format("%s-iam_instance_profile", local.asg_name) : null
  tags        = var.create_asg_per_az ? var.custom_tags : null
  path = "/"
  role = aws_iam_role.role[count.index].name
}

// Scaling metrics
resource "aws_cloudwatch_metric_alarm" "cpu_alarm_low" {
  count = local.legacy_asg_count

  alarm_name = format("%s_alarm_low", aws_autoscaling_group.asg[0].name)
  metric_name = "CPUUtilization"
  alarm_description = "Scale-down if CPU < ${var.scale_in_cpu_threshold}% for 10 minutes"
  namespace = "AWS/EC2"
  statistic = "Average"
  period = 300
  evaluation_periods = 2
  threshold = var.scale_in_cpu_threshold
  alarm_actions = [aws_autoscaling_policy.scale_down_policy[0].arn]
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.asg[0].name
  }
  comparison_operator = "LessThanThreshold"
  lifecycle {
    precondition {
      condition     = var.scale_in_cpu_threshold < var.scale_out_cpu_threshold
      error_message = "scale_in_cpu_threshold (${var.scale_in_cpu_threshold}) must be lower than scale_out_cpu_threshold (${var.scale_out_cpu_threshold}). Keep it at least 20 points lower to avoid flapping."
    }
  }
}
resource "aws_autoscaling_policy" "scale_down_policy" {
  count = local.legacy_asg_count

  autoscaling_group_name = aws_autoscaling_group.asg[0].name
  name = format("%s_scale_down", aws_autoscaling_group.asg[0].name)
  adjustment_type = "ChangeInCapacity"
  cooldown = 300
  scaling_adjustment = -1
}
resource "aws_cloudwatch_metric_alarm" "cpu_alarm_high" {
  count = local.legacy_asg_count

  alarm_name = format("%s_alarm_high", aws_autoscaling_group.asg[0].name)
  metric_name = "CPUUtilization"
  alarm_description = "Scale-up if CPU > ${var.scale_out_cpu_threshold}% for 10 minutes"
  namespace = "AWS/EC2"
  statistic = "Average"
  period = 300
  evaluation_periods = 2
  threshold = var.scale_out_cpu_threshold
  alarm_actions = [aws_autoscaling_policy.scale_up_policy[0].arn]
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.asg[0].name
  }
  comparison_operator = "GreaterThanThreshold"
}
resource "aws_autoscaling_policy" "scale_up_policy" {
  count = local.legacy_asg_count

  autoscaling_group_name = aws_autoscaling_group.asg[0].name
  name = format("%s_scale_up", aws_autoscaling_group.asg[0].name)
  adjustment_type = "ChangeInCapacity"
  cooldown = var.scale_out_cooldown
  scaling_adjustment = 1
}
