data "aws_region" "current" {}

locals {
  alarm_actions                    = length(trimspace(var.alarm_sns_topic_arn)) > 0 ? [var.alarm_sns_topic_arn] : []
  ecs_alarms_enabled               = var.enable_alarms && var.enable_ecs_cpu_alarm
  ec2_alarms_enabled               = var.enable_alarms && var.enable_ec2_cpu_alarm
  rds_free_storage_threshold_bytes = var.rds_free_storage_threshold_gb * 1024 * 1024 * 1024
}

resource "aws_cloudwatch_metric_alarm" "alb_5xx" {
  count = var.enable_alarms ? 1 : 0

  alarm_name          = "${var.name_prefix}-alb-5xx"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.evaluation_periods
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = var.period_seconds
  statistic           = "Sum"
  threshold           = var.alb_5xx_threshold
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
    TargetGroup  = var.target_group_arn_suffix
  }

  alarm_actions = local.alarm_actions
  ok_actions    = local.alarm_actions

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "alb_latency_p95" {
  count = var.enable_alarms ? 1 : 0

  alarm_name          = "${var.name_prefix}-alb-latency-p95"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.evaluation_periods
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = var.period_seconds
  extended_statistic  = "p95"
  threshold           = var.alb_latency_p95_threshold
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
    TargetGroup  = var.target_group_arn_suffix
  }

  alarm_actions = local.alarm_actions
  ok_actions    = local.alarm_actions

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "alb_unhealthy_hosts" {
  count = var.enable_alarms ? 1 : 0

  alarm_name          = "${var.name_prefix}-alb-unhealthy-hosts"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.evaluation_periods
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = var.period_seconds
  statistic           = "Maximum"
  threshold           = var.alb_unhealthy_host_threshold
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
    TargetGroup  = var.target_group_arn_suffix
  }

  alarm_actions = local.alarm_actions
  ok_actions    = local.alarm_actions

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "rds_cpu" {
  count = var.enable_alarms ? 1 : 0

  alarm_name          = "${var.name_prefix}-rds-cpu"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.evaluation_periods
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = var.period_seconds
  statistic           = "Average"
  threshold           = var.rds_cpu_threshold
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBInstanceIdentifier = var.rds_instance_id
  }

  alarm_actions = local.alarm_actions
  ok_actions    = local.alarm_actions

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "rds_free_storage" {
  count = var.enable_alarms ? 1 : 0

  alarm_name          = "${var.name_prefix}-rds-storage"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = var.evaluation_periods
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = var.period_seconds
  statistic           = "Minimum"
  threshold           = local.rds_free_storage_threshold_bytes
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBInstanceIdentifier = var.rds_instance_id
  }

  alarm_actions = local.alarm_actions
  ok_actions    = local.alarm_actions

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "ecs_cpu" {
  count = local.ecs_alarms_enabled ? 1 : 0

  alarm_name          = "${var.name_prefix}-ecs-cpu"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.evaluation_periods
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = var.period_seconds
  statistic           = "Average"
  threshold           = var.ecs_cpu_threshold
  treat_missing_data  = "notBreaching"

  dimensions = {
    ClusterName = var.ecs_cluster_name
    ServiceName = var.ecs_service_name
  }

  alarm_actions = local.alarm_actions
  ok_actions    = local.alarm_actions

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "ecs_memory" {
  count = local.ecs_alarms_enabled ? 1 : 0

  alarm_name          = "${var.name_prefix}-ecs-memory"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.evaluation_periods
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = var.period_seconds
  statistic           = "Average"
  threshold           = var.ecs_memory_threshold
  treat_missing_data  = "notBreaching"

  dimensions = {
    ClusterName = var.ecs_cluster_name
    ServiceName = var.ecs_service_name
  }

  alarm_actions = local.alarm_actions
  ok_actions    = local.alarm_actions

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "ecs_capacity" {
  count = local.ecs_alarms_enabled ? 1 : 0

  alarm_name          = "${var.name_prefix}-ecs-capacity"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.evaluation_periods
  threshold           = 0
  treat_missing_data  = "notBreaching"

  metric_query {
    id          = "running"
    return_data = false

    metric {
      metric_name = "RunningTaskCount"
      namespace   = "AWS/ECS"
      period      = var.period_seconds
      stat        = "Average"

      dimensions = {
        ClusterName = var.ecs_cluster_name
        ServiceName = var.ecs_service_name
      }
    }
  }

  metric_query {
    id          = "desired"
    return_data = false

    metric {
      metric_name = "DesiredTaskCount"
      namespace   = "AWS/ECS"
      period      = var.period_seconds
      stat        = "Average"

      dimensions = {
        ClusterName = var.ecs_cluster_name
        ServiceName = var.ecs_service_name
      }
    }
  }

  metric_query {
    id          = "capacity_gap"
    expression  = "desired - running"
    label       = "DesiredMinusRunning"
    return_data = true
  }

  alarm_actions = local.alarm_actions
  ok_actions    = local.alarm_actions

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "ec2_cpu" {
  count = local.ec2_alarms_enabled ? 1 : 0

  alarm_name          = "${var.name_prefix}-ec2-cpu"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.evaluation_periods
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = var.period_seconds
  statistic           = "Average"
  threshold           = var.ec2_cpu_threshold
  treat_missing_data  = "notBreaching"

  dimensions = {
    AutoScalingGroupName = var.ec2_asg_name
  }

  alarm_actions = local.alarm_actions
  ok_actions    = local.alarm_actions

  tags = var.tags
}

locals {
  ecs_utilization_metrics = var.enable_ecs_cpu_alarm ? [
    [
      "AWS/ECS",
      "CPUUtilization",
      "ClusterName",
      var.ecs_cluster_name,
      "ServiceName",
      var.ecs_service_name,
      {
        label = "ECS CPU"
      }
    ],
    [
      "AWS/ECS",
      "MemoryUtilization",
      "ClusterName",
      var.ecs_cluster_name,
      "ServiceName",
      var.ecs_service_name,
      {
        label = "ECS Memory"
      }
    ]
  ] : []
  ec2_utilization_metrics = var.enable_ec2_cpu_alarm ? [
    [
      "AWS/EC2",
      "CPUUtilization",
      "AutoScalingGroupName",
      var.ec2_asg_name,
      {
        label = "EC2 CPU"
      }
    ]
  ] : []
  compute_utilization_metrics = concat(local.ecs_utilization_metrics, local.ec2_utilization_metrics)

  alb_widgets = [
    {
      type   = "metric"
      x      = 0
      y      = 0
      width  = 12
      height = 6
      properties = {
        title  = "ALB Requests & 5xx"
        region = data.aws_region.current.id
        stat   = "Sum"
        period = var.period_seconds
        metrics = [
          [
            "AWS/ApplicationELB",
            "RequestCount",
            "LoadBalancer",
            var.alb_arn_suffix,
            {
              label = "Requests"
            }
          ],
          [
            "AWS/ApplicationELB",
            "HTTPCode_Target_5XX_Count",
            "LoadBalancer",
            var.alb_arn_suffix,
            "TargetGroup",
            var.target_group_arn_suffix,
            {
              label = "Target 5xx"
            }
          ]
        ]
      }
    },
    {
      type   = "metric"
      x      = 12
      y      = 0
      width  = 12
      height = 6
      properties = {
        title  = "ALB Target Response Time (p95)"
        region = data.aws_region.current.id
        stat   = "p95"
        period = var.period_seconds
        metrics = [
          [
            "AWS/ApplicationELB",
            "TargetResponseTime",
            "LoadBalancer",
            var.alb_arn_suffix,
            "TargetGroup",
            var.target_group_arn_suffix,
            {
              label = "p95"
            }
          ]
        ]
      }
    }
  ]

  compute_widgets = concat(
    length(local.compute_utilization_metrics) > 0 ? [
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          title   = "Compute Utilization"
          region  = data.aws_region.current.id
          stat    = "Average"
          period  = var.period_seconds
          metrics = local.compute_utilization_metrics
        }
      }
    ] : [],
    var.enable_ecs_cpu_alarm ? [
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6
        properties = {
          title  = "ECS Desired vs Running"
          region = data.aws_region.current.id
          stat   = "Average"
          period = var.period_seconds
          metrics = [
            [
              "AWS/ECS",
              "DesiredTaskCount",
              "ClusterName",
              var.ecs_cluster_name,
              "ServiceName",
              var.ecs_service_name,
              {
                label = "Desired"
              }
            ],
            [
              "AWS/ECS",
              "RunningTaskCount",
              "ClusterName",
              var.ecs_cluster_name,
              "ServiceName",
              var.ecs_service_name,
              {
                label = "Running"
              }
            ]
          ]
        }
      }
    ] : []
  )

  rds_widgets = [
    {
      type   = "metric"
      x      = 0
      y      = 12
      width  = 12
      height = 6
      properties = {
        title  = "RDS CPU & Connections"
        region = data.aws_region.current.id
        stat   = "Average"
        period = var.period_seconds
        metrics = [
          [
            "AWS/RDS",
            "CPUUtilization",
            "DBInstanceIdentifier",
            var.rds_instance_id,
            {
              label = "CPU (%)"
            }
          ],
          [
            "AWS/RDS",
            "DatabaseConnections",
            "DBInstanceIdentifier",
            var.rds_instance_id,
            {
              label = "Connections"
              yAxis = "right"
            }
          ]
        ]
      }
    },
    {
      type   = "metric"
      x      = 12
      y      = 12
      width  = 12
      height = 6
      properties = {
        title  = "RDS Free Storage"
        region = data.aws_region.current.id
        stat   = "Minimum"
        period = var.period_seconds
        metrics = [
          [
            "AWS/RDS",
            "FreeStorageSpace",
            "DBInstanceIdentifier",
            var.rds_instance_id,
            {
              label = "Free Storage (Bytes)"
            }
          ]
        ]
      }
    }
  ]

  dashboard_body = jsonencode({
    widgets = concat(local.alb_widgets, local.compute_widgets, local.rds_widgets)
  })
}

resource "aws_cloudwatch_dashboard" "observability" {
  dashboard_name = "${var.name_prefix}-observability"
  dashboard_body = local.dashboard_body
}
