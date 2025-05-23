
module "amis" {
  source = "../amis"
  version_license = var.gateway_version
  amis_url = "https://cgi-cfts-staging.s3.amazonaws.com/utils/amis.yaml"

}

resource "aws_security_group" "permissive_sg" {
  name_prefix = format("%s_PermissiveSecurityGroup", local.asg_name)
  description = "Permissive security group"
  vpc_id = var.vpc_id
  tags = {
    Name = format("%s_PermissiveSecurityGroup", local.asg_name)
    }
  }  

resource "aws_vpc_security_group_ingress_rule" "ingress_rule_ipv4" {
  security_group_id = aws_security_group.permissive_sg.id
  cidr_ipv4         = "0.0.0.0/0"
        from_port    = 0
  ip_protocol       = "-1"
        to_port      = 0
    }

resource "aws_vpc_security_group_egress_rule" "egress_rule_ipv4" {
  security_group_id = aws_security_group.permissive_sg.id
  cidr_ipv4         = "0.0.0.0/0"
    from_port = 0
  ip_protocol       = "-1"
    to_port = 0
  }

resource "aws_vpc_security_group_ingress_rule" "ingress_rule_ipv6" {
  count = var.enable_ipv6 ? 1 : 0
  security_group_id = aws_security_group.permissive_sg.id
  cidr_ipv6         = "::/0"
  from_port         = 0
  ip_protocol       = "-1"
  to_port           = 0
  }  

resource "aws_vpc_security_group_egress_rule" "egress_rule_ipv6" {
  count = var.enable_ipv6 ? 1 : 0
  security_group_id = aws_security_group.permissive_sg.id
  cidr_ipv6         = "::/0"
        from_port    = 0
  ip_protocol       = "-1"
        to_port      = 0
}

resource "aws_launch_template" "asg_launch_template" {
  name_prefix = local.asg_name
  image_id = module.amis.ami_id
  instance_type = var.gateway_instance_type
  key_name = var.key_name
  network_interfaces {
    associate_public_ip_address = var.allocate_public_IP
    security_groups = [aws_security_group.permissive_sg.id]
  }
  metadata_options {
    http_tokens = var.metadata_imdsv2_required ? "required" : "optional"
  }

  iam_instance_profile {
    name = ( var.enable_cloudwatch ? aws_iam_instance_profile.instance_profile[0].name : "")
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

  user_data = base64encode(templatefile("${path.module}/${var.enable_ipv6 ? "asg_userdata_ipv6.yaml" : "asg_userdata.yaml"}", {
    // script's arguments
    PasswordHash = local.gateway_password_hash_base64,
    MaintenanceModePassword = local.maintenance_mode_password_hash_base64,
    EnableCloudWatch = var.enable_cloudwatch,
    EnableInstanceConnect = var.enable_instance_connect,
    Shell = var.admin_shell,
    SICKey = local.gateway_SICkey_base64,
    AllowUploadDownload = var.allow_upload_download,
    BootstrapScript = local.gateway_bootstrap_script64,
    OsVersion = local.version_split
    enable_ipv6 = var.enable_ipv6
  }))
}
resource "aws_autoscaling_group" "asg" {
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

  tag {
    key = "Name"
    value = format("%s%s", var.prefix != "" ? format("%s-", var.prefix) : "", var.gateway_name)
    propagate_at_launch = true
  }

  tag {
    key = "x-chkp-tags"
    value = format("management=%s:template=%s:ip-address=%s", var.management_server, var.configuration_template, var.gateways_provision_address_type)
    propagate_at_launch = true
  }

  tag {
    key = "x-chkp-topology"
    value = "internal"
    propagate_at_launch = true
  }

  tag {
    key = "x-chkp-solution"
    value = "autoscale_gwlb"
    propagate_at_launch = true
  }

  dynamic "tag" {
    for_each = var.instances_tags
    content {
      key = tag.key
      value = tag.value
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
  name_prefix = format("%s-iam_role", local.asg_name)
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy_document.json
  path = "/"
}
module "attach_cloudwatch_policy" {
  source = "../cloudwatch_policy"
  count = local.create_iam_role
  role = aws_iam_role.role[count.index].name
  tag_name = local.asg_name
}
resource "aws_iam_instance_profile" "instance_profile" {
  count = local.create_iam_role
  name_prefix = format("%s-iam_instance_profile", local.asg_name)
  path = "/"
  role = aws_iam_role.role[count.index].name
}

// Scaling metrics
resource "aws_cloudwatch_metric_alarm" "cpu_alarm_low" {
  alarm_name = format("%s_alarm_low", aws_autoscaling_group.asg.name)
  metric_name = "CPUUtilization"
  alarm_description = "Scale-down if CPU < 60% for 10 minutes"
  namespace = "AWS/EC2"
  statistic = "Average"
  period = 300
  evaluation_periods = 2
  threshold = 60
  alarm_actions = [aws_autoscaling_policy.scale_down_policy.arn]
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.asg.name
  }
  comparison_operator = "LessThanThreshold"
}
resource "aws_autoscaling_policy" "scale_down_policy" {
  autoscaling_group_name = aws_autoscaling_group.asg.name
  name = format("%s_scale_down", aws_autoscaling_group.asg.name)
  adjustment_type = "ChangeInCapacity"
  cooldown = 300
  scaling_adjustment = -1
}
resource "aws_cloudwatch_metric_alarm" "cpu_alarm_high" {
  alarm_name = format("%s_alarm_high", aws_autoscaling_group.asg.name)
  metric_name = "CPUUtilization"
  alarm_description = "Scale-up if CPU > 80% for 10 minutes"
  namespace = "AWS/EC2"
  statistic = "Average"
  period = 300
  evaluation_periods = 2
  threshold = 80
  alarm_actions = [aws_autoscaling_policy.scale_up_policy.arn]
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.asg.name
  }
  comparison_operator = "GreaterThanThreshold"
}
resource "aws_autoscaling_policy" "scale_up_policy" {
  autoscaling_group_name = aws_autoscaling_group.asg.name
  name = format("%s_scale_up", aws_autoscaling_group.asg.name)
  adjustment_type = "ChangeInCapacity"
  cooldown = 300
  scaling_adjustment = 1
}
