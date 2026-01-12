mock_provider "aws" {}

run "observability_baseline" {
  command = plan

  variables {
    name_prefix             = "test"
    alb_arn_suffix          = "app/test/1234567890abcdef"
    target_group_arn_suffix = "targetgroup/test/1234567890abcdef"
    rds_instance_id         = "test-db"
    ecs_cluster_name        = "test-ecs"
    ecs_service_name        = "test-service"
    alarm_sns_topic_arn     = "arn:aws:sns:us-east-1:123456789012:alarms"
    alb_5xx_threshold       = 10
    rds_cpu_threshold       = 85
    ecs_cpu_threshold       = 75
    evaluation_periods      = 3
    tags = {
      Project     = "test"
      Environment = "test"
      Service     = "test"
      Owner       = "test"
      CostCenter  = "test"
      ManagedBy   = "Terraform"
      Repository  = "aws-platform-starter"
    }
  }

  assert {
    condition     = aws_cloudwatch_metric_alarm.alb_5xx.namespace == "AWS/ApplicationELB" && aws_cloudwatch_metric_alarm.alb_5xx.metric_name == "HTTPCode_Target_5XX_Count"
    error_message = "expected ALB 5xx alarm namespace and metric name"
  }

  assert {
    condition     = aws_cloudwatch_metric_alarm.alb_5xx.threshold == 10 && aws_cloudwatch_metric_alarm.alb_5xx.evaluation_periods == 3
    error_message = "expected ALB 5xx alarm threshold and evaluation periods to match inputs"
  }

  assert {
    condition     = aws_cloudwatch_metric_alarm.alb_5xx.dimensions["LoadBalancer"] == "app/test/1234567890abcdef" && aws_cloudwatch_metric_alarm.alb_5xx.dimensions["TargetGroup"] == "targetgroup/test/1234567890abcdef"
    error_message = "expected ALB 5xx alarm dimensions to match ALB and target group suffixes"
  }

  assert {
    condition     = toset(aws_cloudwatch_metric_alarm.alb_5xx.alarm_actions) == toset(["arn:aws:sns:us-east-1:123456789012:alarms"]) && toset(aws_cloudwatch_metric_alarm.alb_5xx.ok_actions) == toset(["arn:aws:sns:us-east-1:123456789012:alarms"])
    error_message = "expected ALB 5xx alarm to wire SNS actions"
  }

  assert {
    condition     = aws_cloudwatch_metric_alarm.alb_5xx.treat_missing_data == "notBreaching"
    error_message = "expected ALB 5xx alarm to treat missing data as not breaching"
  }

  assert {
    condition     = aws_cloudwatch_metric_alarm.ecs_cpu[0].namespace == "AWS/ECS" && aws_cloudwatch_metric_alarm.ecs_cpu[0].metric_name == "CPUUtilization"
    error_message = "expected ECS CPU alarm namespace and metric name"
  }

  assert {
    condition     = aws_cloudwatch_metric_alarm.ecs_cpu[0].threshold == 75 && aws_cloudwatch_metric_alarm.ecs_cpu[0].evaluation_periods == 3
    error_message = "expected ECS CPU alarm threshold and evaluation periods to match inputs"
  }

  assert {
    condition     = aws_cloudwatch_metric_alarm.ecs_cpu[0].dimensions["ClusterName"] == "test-ecs" && aws_cloudwatch_metric_alarm.ecs_cpu[0].dimensions["ServiceName"] == "test-service"
    error_message = "expected ECS CPU alarm dimensions to match cluster and service names"
  }

  assert {
    condition     = toset(aws_cloudwatch_metric_alarm.ecs_cpu[0].alarm_actions) == toset(["arn:aws:sns:us-east-1:123456789012:alarms"]) && toset(aws_cloudwatch_metric_alarm.ecs_cpu[0].ok_actions) == toset(["arn:aws:sns:us-east-1:123456789012:alarms"])
    error_message = "expected ECS CPU alarm to wire SNS actions"
  }

  assert {
    condition     = aws_cloudwatch_metric_alarm.ecs_cpu[0].treat_missing_data == "notBreaching"
    error_message = "expected ECS CPU alarm to treat missing data as not breaching"
  }

  assert {
    condition     = aws_cloudwatch_metric_alarm.rds_cpu.namespace == "AWS/RDS" && aws_cloudwatch_metric_alarm.rds_cpu.metric_name == "CPUUtilization"
    error_message = "expected RDS CPU alarm namespace and metric name"
  }

  assert {
    condition     = aws_cloudwatch_metric_alarm.rds_cpu.threshold == 85 && aws_cloudwatch_metric_alarm.rds_cpu.evaluation_periods == 3
    error_message = "expected RDS CPU alarm threshold and evaluation periods to match inputs"
  }

  assert {
    condition     = aws_cloudwatch_metric_alarm.rds_cpu.dimensions["DBInstanceIdentifier"] == "test-db"
    error_message = "expected RDS CPU alarm dimensions to match instance identifier"
  }

  assert {
    condition     = toset(aws_cloudwatch_metric_alarm.rds_cpu.alarm_actions) == toset(["arn:aws:sns:us-east-1:123456789012:alarms"]) && toset(aws_cloudwatch_metric_alarm.rds_cpu.ok_actions) == toset(["arn:aws:sns:us-east-1:123456789012:alarms"])
    error_message = "expected RDS CPU alarm to wire SNS actions"
  }

  assert {
    condition     = aws_cloudwatch_metric_alarm.rds_cpu.treat_missing_data == "notBreaching"
    error_message = "expected RDS CPU alarm to treat missing data as not breaching"
  }
}

run "observability_sns_disabled" {
  command = plan

  variables {
    name_prefix             = "test"
    alb_arn_suffix          = "app/test/1234567890abcdef"
    target_group_arn_suffix = "targetgroup/test/1234567890abcdef"
    rds_instance_id         = "test-db"
    ecs_cluster_name        = "test-ecs"
    ecs_service_name        = "test-service"
    alarm_sns_topic_arn     = ""
    tags = {
      Project     = "test"
      Environment = "test"
      Service     = "test"
      Owner       = "test"
      CostCenter  = "test"
      ManagedBy   = "Terraform"
      Repository  = "aws-platform-starter"
    }
  }

  assert {
    condition     = length(aws_cloudwatch_metric_alarm.alb_5xx.alarm_actions) == 0 && length(aws_cloudwatch_metric_alarm.alb_5xx.ok_actions) == 0
    error_message = "expected ALB 5xx alarm actions to be empty when SNS is disabled"
  }

  assert {
    condition     = length(aws_cloudwatch_metric_alarm.ecs_cpu[0].alarm_actions) == 0 && length(aws_cloudwatch_metric_alarm.ecs_cpu[0].ok_actions) == 0
    error_message = "expected ECS CPU alarm actions to be empty when SNS is disabled"
  }

  assert {
    condition     = length(aws_cloudwatch_metric_alarm.rds_cpu.alarm_actions) == 0 && length(aws_cloudwatch_metric_alarm.rds_cpu.ok_actions) == 0
    error_message = "expected RDS CPU alarm actions to be empty when SNS is disabled"
  }
}

run "observability_missing_ecs_identifiers" {
  command = plan

  variables {
    name_prefix             = "test"
    alb_arn_suffix          = "app/test/1234567890abcdef"
    target_group_arn_suffix = "targetgroup/test/1234567890abcdef"
    rds_instance_id         = "test-db"
    ecs_cluster_name        = ""
    ecs_service_name        = ""
    alarm_sns_topic_arn     = "arn:aws:sns:us-east-1:123456789012:alarms"
    tags = {
      Project     = "test"
      Environment = "test"
      Service     = "test"
      Owner       = "test"
      CostCenter  = "test"
      ManagedBy   = "Terraform"
      Repository  = "aws-platform-starter"
    }
  }

  expect_failures = [var.ecs_cluster_name, var.ecs_service_name]
}
