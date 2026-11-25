// Preserve existing ASGs when adding count for the optional per-AZ topology.
moved {
  from = aws_autoscaling_group.asg
  to   = aws_autoscaling_group.asg[0]
}

moved {
  from = aws_cloudwatch_metric_alarm.cpu_alarm_low
  to   = aws_cloudwatch_metric_alarm.cpu_alarm_low[0]
}

moved {
  from = aws_cloudwatch_metric_alarm.cpu_alarm_high
  to   = aws_cloudwatch_metric_alarm.cpu_alarm_high[0]
}

moved {
  from = aws_autoscaling_policy.scale_down_policy
  to   = aws_autoscaling_policy.scale_down_policy[0]
}

moved {
  from = aws_autoscaling_policy.scale_up_policy
  to   = aws_autoscaling_policy.scale_up_policy[0]
}
