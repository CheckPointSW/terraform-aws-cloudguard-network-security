
module "amis" {
  source = "../amis"
  version_license = var.gateway_version
}

resource "aws_security_group" "permissive_sg" {
  count = var.existing_security_group_id == "" ? 1 : 0
  name_prefix = format("%s_PermissiveSecurityGroup", local.asg_name)
  description = "Permissive security group"
  vpc_id = var.vpc_id

  dynamic "ingress" {
    for_each = [for rule in var.gateways_security_rules : rule if rule.direction == "ingress"]
    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = [for cidr in ingress.value.cidr_blocks : cidr if strcontains(cidr, ".")]
      ipv6_cidr_blocks = local.ipv6_enabled ? [for cidr in ingress.value.cidr_blocks : cidr if strcontains(cidr, ":")] : []
    }
  }

  dynamic ingress {
    for_each = length([for rule in var.gateways_security_rules : rule if rule.direction == "ingress"]) == 0 ? [1] : []
    content{
        from_port    = 0
        to_port      = 0
        protocol     = "-1"
        cidr_blocks  = ["0.0.0.0/0"]
        ipv6_cidr_blocks = local.ipv6_enabled ? ["::/0"] : []
    }
  }

  dynamic "egress" {
    for_each = [for rule in var.gateways_security_rules : rule if rule.direction == "egress"]
    content {
      from_port   = egress.value.from_port
      to_port     = egress.value.to_port
      protocol    = egress.value.protocol
      cidr_blocks = [for cidr in egress.value.cidr_blocks : cidr if strcontains(cidr, ".")]
      ipv6_cidr_blocks = local.ipv6_enabled ? [for cidr in egress.value.cidr_blocks : cidr if strcontains(cidr, ":")] : []
    }
  }

  dynamic egress {
    for_each = length([for rule in var.gateways_security_rules : rule if rule.direction == "egress"]) == 0 ? [1] : []
    content{
        from_port    = 0
        to_port      = 0
        protocol     = "-1"
        cidr_blocks  = ["0.0.0.0/0"]
        ipv6_cidr_blocks = local.ipv6_enabled ? ["::/0"] : []
    }
  }
  tags = {
    Name = format("%s_PermissiveSecurityGroup", local.asg_name)
  }
}

resource "aws_launch_template" "asg_launch_template" {
  name_prefix = local.asg_name
  image_id = module.amis.ami_id
  instance_type = var.gateway_instance_type
  key_name = var.key_name

  # Only define the primary network interface in launch template
  # The primary ENI is now in private subnet (no public IP)
  # The second ENI will be attached dynamically via Lambda function in public subnet
  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [var.existing_security_group_id == "" ? aws_security_group.permissive_sg[0].id : var.existing_security_group_id]
  }

  tag_specifications {
    resource_type = "network-interface"
    tags = {
      x-chkp-anti-spoofing = "false"
    }
  }

  metadata_options {
    http_tokens = var.metadata_imdsv2_required ? "required" : "optional"
    http_protocol_ipv6 = local.ipv6_enabled ? "enabled" : "disabled"
    instance_metadata_tags = "enabled"
  }

  dynamic "iam_instance_profile" {
    for_each = var.enable_cloudwatch ? [1] : []
    content {
      name = aws_iam_instance_profile.instance_profile[0].name
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

  user_data = base64encode(templatefile("${path.module}/asg_userdata.yaml", {
    // script's arguments
    EnableCloudWatch = var.enable_cloudwatch,
    SICKey = local.gateway_SICkey_base64,
    OsVersion = local.version_split,
    AllowUploadDownload = var.allow_upload_download,
    shell = var.admin_shell,
    EnableInstanceConnect = var.enable_instance_connect,
    PasswordHash = local.gateway_password_hash_base64,
    MaintenanceModePassword = local.maintenance_mode_password_hash_base64,
    BootstrapScript = local.gateway_bootstrap_script64,
    IPMode = var.ip_mode == "IPv4" ? "false" : "true",
    TemplateName = local.template_name
  }))
}
resource "aws_autoscaling_group" "asg" {
  name_prefix = local.asg_name
  launch_template {
    id = aws_launch_template.asg_launch_template.id
    version = aws_launch_template.asg_launch_template.latest_version
  }
  min_size = 0
  max_size = var.maximum_group_size
  desired_capacity = 0
  target_group_arns = var.target_groups
  vpc_zone_identifier = var.gateways_private_subnets
  health_check_grace_period = 3600
  health_check_type = "ELB"

  tag {
    key = "Name"
    value = local.gateway_name
    propagate_at_launch = true
  }

  tag {
    key = "x-chkp-tags"
    value = format("management=%s:template=%s:ip-address=%s", var.management_server, var.configuration_template, var.gateways_provision_address_type)
    propagate_at_launch = true
  }

  tag {
    key = "x-chkp-topology"
    value = "private"
    propagate_at_launch = true
  }

  tag {
    key = "x-chkp-solution"
    value = "autoscale_gwlb_dual_arm"
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

# Lambda function for attaching second ENI in different subnet
resource "aws_iam_role" "lambda_multi_eni_role" {
  name_prefix = format("%s-lambda-eni-role", local.asg_name)
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "lambda_multi_eni_policy" {
  name_prefix = format("%s-lambda-eni-policy", local.asg_name)
  role = aws_iam_role.lambda_multi_eni_role.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # Allow Lambda to write logs to CloudWatch for monitoring and debugging
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:log-group:/aws/lambda/${local.lambda_name}:*"
      },
      {
        # Allow Lambda to create and attach second ENI to instances in public subnet
        Effect = "Allow"
        Action = [
          "ec2:CreateNetworkInterface",
          "ec2:AttachNetworkInterface",
          "ec2:ModifyNetworkInterfaceAttribute"
        ]
        Resource = [
          "arn:aws:ec2:*:*:network-interface/*",
          "arn:aws:ec2:*:*:instance/*",
          "arn:aws:ec2:*:*:subnet/*",
          "arn:aws:ec2:*:*:security-group/*"
        ]
      },
      {
        # Allow Lambda to tag ENIs, instances, and EIPs for identification and anti-spoofing config
        Effect = "Allow"
        Action = "ec2:CreateTags"
        Resource = [
          "arn:aws:ec2:*:*:network-interface/*",
          "arn:aws:ec2:*:*:instance/*",
          "arn:aws:ec2:*:*:elastic-ip/*"
        ]
      },
      {
        # Allow Lambda to allocate EIP for public subnet ENI and release it on termination
        Effect = "Allow"
        Action = [
          "ec2:AllocateAddress",
          "ec2:ReleaseAddress"
        ]
        Resource = [
          "arn:aws:ec2:*:*:elastic-ip/*",
          "arn:aws:ec2:*:*:ipv4pool-ec2/*",
          "arn:aws:ec2::*:ipam-pool/*"
        ]
      },
      {
        # Allow Lambda to associate/disassociate EIP with ENI (requires wildcard - no resource-level permissions)
        Effect = "Allow"
        Action = [
          "ec2:AssociateAddress",
          "ec2:DisassociateAddress"
        ]
        Resource = "*"
      },
      {
        # Allow Lambda to query AWS resources for AZ mapping and cleanup (read-only, requires wildcard)
        Effect = "Allow"
        Action = [
          "ec2:DescribeNetworkInterfaces",
          "ec2:DescribeSubnets",
          "ec2:DescribeInstances",
          "ec2:DescribeAddresses"
        ]
        Resource = "*"
      },
      {
        # Allow Lambda to use IPAM pools for EIP allocation if configured
        Effect = "Allow"
        Action = [
          "ec2:AllocateIpamPoolCidr"
        ]
        Resource = "arn:aws:ec2::*:ipam-pool/*"
      },
      {
        # Allow Lambda to describe IPAM pools and query pool information (read-only, requires wildcard)
        Effect = "Allow"
        Action = [
          "ec2:DescribePublicIpv4Pools",
          "ec2:GetIpamPoolAllocations",
          "ec2:DescribeIpamPools",
          "ec2:GetIpamPoolCidrs"
        ]
        Resource = "*"
      },
      {
        # Allow Lambda to signal ASG that instance launch configuration is complete
        Effect = "Allow"
        Action = "autoscaling:CompleteLifecycleAction"
        Resource = aws_autoscaling_group.asg.arn
      },
      {
        # Allow Lambda to fetch the actual Lambda code from S3 (bootstrap pattern)
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion"
        ]
        Resource = "arn:aws:s3:::cgns-cft-utils/gwlb/dual_arm_lifecycle_handler.py"
      },
      {
        # Allow Lambda to update its own config to pin S3 code version
        Effect = "Allow"
        Action = [
          "lambda:GetFunctionConfiguration",
          "lambda:UpdateFunctionConfiguration"
        ]
        Resource = "arn:aws:lambda:*:*:function:${local.lambda_name}"
      }
    ]
  })
}

# Lambda function to attach second ENI
resource "aws_lambda_function" "multi_eni_lambda" {
  filename = data.archive_file.lambda_zip.output_path
  function_name = local.lambda_name
  role = aws_iam_role.lambda_multi_eni_role.arn
  handler = "lambda_s3_loader.lambda_handler"
  runtime = "python3.11"
  timeout = 300
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  
  environment {
    variables = {
      PUBLIC_SUBNETS = jsonencode(var.gateways_public_subnets)
      PRIVATE_SUBNETS = jsonencode(var.gateways_private_subnets)
      S3_BUCKET = "cgns-cft-utils"
      S3_KEY = "gwlb/dual_arm_lifecycle_handler.py"
      LAMBDA_AUTO_UPDATE = tostring(var.lambda_auto_update)
      IPAM_POOL_ID = var.ipam_pool_id
    }
  }
  
  # Prevent Terraform from overwriting S3_VERSION_ID that gets pinned by the bootstrap script
  lifecycle {
    ignore_changes = [
      environment[0].variables["S3_VERSION_ID"]
    ]
  }
  
  depends_on = [
    aws_iam_role_policy.lambda_multi_eni_policy
  ]
}

# Create the Lambda deployment package with S3 bootstrap code
data "archive_file" "lambda_zip" {
  type = "zip"
  output_path = "${path.module}/dual_arm_lifecycle_handler.zip"
  source {
    content = file("${path.module}/lambda_s3_loader.py")
    filename = "lambda_s3_loader.py"
  }
}

# Auto Scaling lifecycle hooks
resource "aws_autoscaling_lifecycle_hook" "launch_hook" {
  name = format("%s-launch-hook", local.asg_name)
  autoscaling_group_name = aws_autoscaling_group.asg.name
  default_result = "CONTINUE"
  heartbeat_timeout = 120
  lifecycle_transition = "autoscaling:EC2_INSTANCE_LAUNCHING"
}

resource "aws_autoscaling_lifecycle_hook" "terminate_hook" {
  name = format("%s-terminate-hook", local.asg_name)
  autoscaling_group_name = aws_autoscaling_group.asg.name
  default_result = "CONTINUE"
  heartbeat_timeout = 300
  lifecycle_transition = "autoscaling:EC2_INSTANCE_TERMINATING"
}

# EventBridge rules to trigger Lambda
resource "aws_cloudwatch_event_rule" "asg_launch_rule" {
  name_prefix = format("%s-launch-rule", local.asg_name)
  description = "Capture ASG launch events"
  
  event_pattern = jsonencode({
    source = ["aws.autoscaling"]
    detail-type = ["EC2 Instance-launch Lifecycle Action"]
    detail = {
      AutoScalingGroupName = [aws_autoscaling_group.asg.name]
      LifecycleHookName = [aws_autoscaling_lifecycle_hook.launch_hook.name]
    }
  })
}

resource "aws_cloudwatch_event_rule" "asg_terminate_rule" {
  name_prefix = format("%s-terminate-rule", local.asg_name)
  description = "Capture ASG terminate lifecycle events"
  
  event_pattern = jsonencode({
    source = ["aws.autoscaling"]
    detail-type = ["EC2 Instance-terminate Lifecycle Action"]
    detail = {
      AutoScalingGroupName = [aws_autoscaling_group.asg.name]
      LifecycleHookName = [aws_autoscaling_lifecycle_hook.terminate_hook.name]
    }
  })
}

resource "aws_cloudwatch_event_target" "lambda_target" {
  rule = aws_cloudwatch_event_rule.asg_launch_rule.name
  target_id = "SendToLambda"
  arn = aws_lambda_function.multi_eni_lambda.arn
}

resource "aws_cloudwatch_event_target" "lambda_terminate_target" {
  rule = aws_cloudwatch_event_rule.asg_terminate_rule.name
  target_id = "SendToLambdaTerminate"
  arn = aws_lambda_function.multi_eni_lambda.arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id = "AllowExecutionFromEventBridge"
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.multi_eni_lambda.function_name
  principal = "events.amazonaws.com"
  source_arn = aws_cloudwatch_event_rule.asg_launch_rule.arn
}

resource "aws_lambda_permission" "allow_eventbridge_terminate" {
  statement_id = "AllowExecutionFromEventBridgeTerminate"
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.multi_eni_lambda.function_name
  principal = "events.amazonaws.com"
  source_arn = aws_cloudwatch_event_rule.asg_terminate_rule.arn
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

# Update ASG minimum size after Lambda infrastructure is ready
# This creates a "virtual" update by managing the desired_capacity which triggers min_size enforcement
resource "aws_autoscaling_schedule" "scale_up_after_lambda" {
  scheduled_action_name  = "${aws_autoscaling_group.asg.name}-initial-scale"
  min_size               = var.minimum_group_size
  max_size               = var.maximum_group_size
  desired_capacity       = var.minimum_group_size
  start_time            = timeadd(timestamp(), "30s")  # Start 30 seconds from now
  autoscaling_group_name = aws_autoscaling_group.asg.name
  
  depends_on = [
    aws_lambda_function.multi_eni_lambda,
    aws_autoscaling_lifecycle_hook.launch_hook,
    aws_cloudwatch_event_rule.asg_launch_rule,
    aws_cloudwatch_event_rule.asg_terminate_rule,
    aws_cloudwatch_event_target.lambda_target,
    aws_cloudwatch_event_target.lambda_terminate_target,
    aws_lambda_permission.allow_eventbridge,
    aws_lambda_permission.allow_eventbridge_terminate
  ]
}