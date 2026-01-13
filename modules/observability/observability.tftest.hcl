mock_provider "aws" {}

run "observability_baseline" {
  command = plan

  variables {
    name_prefix                   = "test"
    alb_arn_suffix                = "app/test/1234567890abcdef"
    target_group_arn_suffix       = "targetgroup/test/1234567890abcdef"
    rds_instance_id               = "test-db"
    ecs_cluster_name              = "test-ecs"
    ecs_service_name              = "test-service"
    enable_ec2_cpu_alarm          = true
    ec2_asg_name                  = "test-asg"
    alarm_sns_topic_arn           = "arn:aws:sns:us-east-1:123456789012:alarms"
    alb_5xx_threshold             = 10
    alb_latency_p95_threshold     = 0.8
    alb_unhealthy_host_threshold  = 2
    rds_cpu_threshold             = 85
    rds_free_storage_threshold_gb = 10
    ecs_cpu_threshold             = 75
    ecs_memory_threshold          = 70
    evaluation_periods            = 3
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
    condition     = aws_cloudwatch_metric_alarm.alb_5xx[0].namespace == "AWS/ApplicationELB" && aws_cloudwatch_metric_alarm.alb_5xx[0].metric_name == "HTTPCode_Target_5XX_Count"
    error_message = "expected ALB 5xx alarm namespace and metric name"
  }

  assert {
    condition     = aws_cloudwatch_metric_alarm.alb_5xx[0].threshold == 10 && aws_cloudwatch_metric_alarm.alb_5xx[0].evaluation_periods == 3
    error_message = "expected ALB 5xx alarm threshold and evaluation periods to match inputs"
  }

  assert {
    condition     = aws_cloudwatch_metric_alarm.alb_5xx[0].dimensions["LoadBalancer"] == "app/test/1234567890abcdef" && aws_cloudwatch_metric_alarm.alb_5xx[0].dimensions["TargetGroup"] == "targetgroup/test/1234567890abcdef"
    error_message = "expected ALB 5xx alarm dimensions to match ALB and target group suffixes"
  }

  assert {
    condition     = toset(aws_cloudwatch_metric_alarm.alb_5xx[0].alarm_actions) == toset(["arn:aws:sns:us-east-1:123456789012:alarms"]) && toset(aws_cloudwatch_metric_alarm.alb_5xx[0].ok_actions) == toset(["arn:aws:sns:us-east-1:123456789012:alarms"])
    error_message = "expected ALB 5xx alarm to wire SNS actions"
  }

  assert {
    condition     = aws_cloudwatch_metric_alarm.alb_5xx[0].treat_missing_data == "notBreaching"
    error_message = "expected ALB 5xx alarm to treat missing data as not breaching"
  }

  assert {
    condition     = aws_cloudwatch_metric_alarm.alb_latency_p95[0].namespace == "AWS/ApplicationELB" && aws_cloudwatch_metric_alarm.alb_latency_p95[0].metric_name == "TargetResponseTime"
    error_message = "expected ALB latency alarm namespace and metric name"
  }

  assert {
    condition     = aws_cloudwatch_metric_alarm.alb_latency_p95[0].extended_statistic == "p95" && aws_cloudwatch_metric_alarm.alb_latency_p95[0].threshold == 0.8
    error_message = "expected ALB latency alarm to use p95 and threshold input"
  }

  assert {
    condition     = aws_cloudwatch_metric_alarm.alb_latency_p95[0].dimensions["LoadBalancer"] == "app/test/1234567890abcdef" && aws_cloudwatch_metric_alarm.alb_latency_p95[0].dimensions["TargetGroup"] == "targetgroup/test/1234567890abcdef"
    error_message = "expected ALB latency alarm dimensions to match ALB and target group suffixes"
  }

  assert {
    condition     = aws_cloudwatch_metric_alarm.alb_unhealthy_hosts[0].metric_name == "UnHealthyHostCount" && aws_cloudwatch_metric_alarm.alb_unhealthy_hosts[0].threshold == 2
    error_message = "expected ALB unhealthy host alarm metric and threshold"
  }

  assert {
    condition     = toset(aws_cloudwatch_metric_alarm.alb_latency_p95[0].alarm_actions) == toset(["arn:aws:sns:us-east-1:123456789012:alarms"]) && toset(aws_cloudwatch_metric_alarm.alb_unhealthy_hosts[0].alarm_actions) == toset(["arn:aws:sns:us-east-1:123456789012:alarms"])
    error_message = "expected ALB latency and unhealthy host alarms to wire SNS actions"
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
    condition     = aws_cloudwatch_metric_alarm.ecs_memory[0].metric_name == "MemoryUtilization" && aws_cloudwatch_metric_alarm.ecs_memory[0].threshold == 70
    error_message = "expected ECS memory alarm metric and threshold"
  }

  assert {
    condition     = aws_cloudwatch_metric_alarm.ecs_capacity[0].comparison_operator == "GreaterThanThreshold" && aws_cloudwatch_metric_alarm.ecs_capacity[0].threshold == 0
    error_message = "expected ECS capacity alarm to alert on desired minus running tasks"
  }

  assert {
    condition     = contains([for query in aws_cloudwatch_metric_alarm.ecs_capacity[0].metric_query : query.expression if query.expression != null], "desired - running")
    error_message = "expected ECS capacity alarm metric math expression to compare desired and running tasks"
  }

  assert {
    condition     = toset(aws_cloudwatch_metric_alarm.ecs_memory[0].alarm_actions) == toset(["arn:aws:sns:us-east-1:123456789012:alarms"]) && toset(aws_cloudwatch_metric_alarm.ecs_capacity[0].alarm_actions) == toset(["arn:aws:sns:us-east-1:123456789012:alarms"])
    error_message = "expected ECS memory and capacity alarms to wire SNS actions"
  }

  assert {
    condition     = aws_cloudwatch_metric_alarm.rds_cpu[0].namespace == "AWS/RDS" && aws_cloudwatch_metric_alarm.rds_cpu[0].metric_name == "CPUUtilization"
    error_message = "expected RDS CPU alarm namespace and metric name"
  }

  assert {
    condition     = aws_cloudwatch_metric_alarm.rds_cpu[0].threshold == 85 && aws_cloudwatch_metric_alarm.rds_cpu[0].evaluation_periods == 3
    error_message = "expected RDS CPU alarm threshold and evaluation periods to match inputs"
  }

  assert {
    condition     = aws_cloudwatch_metric_alarm.rds_cpu[0].dimensions["DBInstanceIdentifier"] == "test-db"
    error_message = "expected RDS CPU alarm dimensions to match instance identifier"
  }

  assert {
    condition     = toset(aws_cloudwatch_metric_alarm.rds_cpu[0].alarm_actions) == toset(["arn:aws:sns:us-east-1:123456789012:alarms"]) && toset(aws_cloudwatch_metric_alarm.rds_cpu[0].ok_actions) == toset(["arn:aws:sns:us-east-1:123456789012:alarms"])
    error_message = "expected RDS CPU alarm to wire SNS actions"
  }

  assert {
    condition     = aws_cloudwatch_metric_alarm.rds_cpu[0].treat_missing_data == "notBreaching"
    error_message = "expected RDS CPU alarm to treat missing data as not breaching"
  }

  assert {
    condition     = aws_cloudwatch_metric_alarm.rds_free_storage[0].metric_name == "FreeStorageSpace" && aws_cloudwatch_metric_alarm.rds_free_storage[0].threshold == 10737418240
    error_message = "expected RDS free storage alarm to use the GiB threshold input"
  }

  assert {
    condition     = aws_cloudwatch_metric_alarm.ec2_cpu[0].metric_name == "CPUUtilization" && aws_cloudwatch_metric_alarm.ec2_cpu[0].dimensions["AutoScalingGroupName"] == "test-asg"
    error_message = "expected EC2 CPU alarm metric and ASG dimension"
  }

  assert {
    condition     = aws_cloudwatch_dashboard.observability.dashboard_name == "test-observability"
    error_message = "expected observability dashboard to use the name prefix"
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
    enable_ec2_cpu_alarm    = true
    ec2_asg_name            = "test-asg"
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
    condition     = length(aws_cloudwatch_metric_alarm.alb_5xx[0].alarm_actions) == 0 && length(aws_cloudwatch_metric_alarm.alb_5xx[0].ok_actions) == 0
    error_message = "expected ALB 5xx alarm actions to be empty when SNS is disabled"
  }

  assert {
    condition     = length(aws_cloudwatch_metric_alarm.alb_latency_p95[0].alarm_actions) == 0 && length(aws_cloudwatch_metric_alarm.alb_latency_p95[0].ok_actions) == 0 && length(aws_cloudwatch_metric_alarm.alb_unhealthy_hosts[0].alarm_actions) == 0 && length(aws_cloudwatch_metric_alarm.alb_unhealthy_hosts[0].ok_actions) == 0
    error_message = "expected ALB latency and unhealthy host alarms to be empty when SNS is disabled"
  }

  assert {
    condition     = length(aws_cloudwatch_metric_alarm.ecs_cpu[0].alarm_actions) == 0 && length(aws_cloudwatch_metric_alarm.ecs_cpu[0].ok_actions) == 0 && length(aws_cloudwatch_metric_alarm.ecs_memory[0].alarm_actions) == 0 && length(aws_cloudwatch_metric_alarm.ecs_memory[0].ok_actions) == 0
    error_message = "expected ECS CPU and memory alarm actions to be empty when SNS is disabled"
  }

  assert {
    condition     = length(aws_cloudwatch_metric_alarm.ecs_capacity[0].alarm_actions) == 0 && length(aws_cloudwatch_metric_alarm.ecs_capacity[0].ok_actions) == 0
    error_message = "expected ECS capacity alarm actions to be empty when SNS is disabled"
  }

  assert {
    condition     = length(aws_cloudwatch_metric_alarm.rds_cpu[0].alarm_actions) == 0 && length(aws_cloudwatch_metric_alarm.rds_cpu[0].ok_actions) == 0 && length(aws_cloudwatch_metric_alarm.rds_free_storage[0].alarm_actions) == 0 && length(aws_cloudwatch_metric_alarm.rds_free_storage[0].ok_actions) == 0
    error_message = "expected RDS alarm actions to be empty when SNS is disabled"
  }

  assert {
    condition     = length(aws_cloudwatch_metric_alarm.ec2_cpu[0].alarm_actions) == 0 && length(aws_cloudwatch_metric_alarm.ec2_cpu[0].ok_actions) == 0
    error_message = "expected EC2 CPU alarm actions to be empty when SNS is disabled"
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

run "observability_alarms_disabled" {
  command = plan

  variables {
    name_prefix             = "test"
    alb_arn_suffix          = "app/test/1234567890abcdef"
    target_group_arn_suffix = "targetgroup/test/1234567890abcdef"
    rds_instance_id         = "test-db"
    ecs_cluster_name        = "test-ecs"
    ecs_service_name        = "test-service"
    enable_ec2_cpu_alarm    = true
    ec2_asg_name            = "test-asg"
    enable_alarms           = false
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
    condition     = length(aws_cloudwatch_metric_alarm.alb_5xx) == 0 && length(aws_cloudwatch_metric_alarm.alb_latency_p95) == 0 && length(aws_cloudwatch_metric_alarm.alb_unhealthy_hosts) == 0
    error_message = "expected ALB alarms to be skipped when enable_alarms is false"
  }

  assert {
    condition     = length(aws_cloudwatch_metric_alarm.ecs_cpu) == 0 && length(aws_cloudwatch_metric_alarm.ecs_memory) == 0 && length(aws_cloudwatch_metric_alarm.ecs_capacity) == 0
    error_message = "expected ECS alarms to be skipped when enable_alarms is false"
  }

  assert {
    condition     = length(aws_cloudwatch_metric_alarm.ec2_cpu) == 0
    error_message = "expected EC2 alarms to be skipped when enable_alarms is false"
  }

  assert {
    condition     = length(aws_cloudwatch_metric_alarm.rds_cpu) == 0 && length(aws_cloudwatch_metric_alarm.rds_free_storage) == 0
    error_message = "expected RDS alarms to be skipped when enable_alarms is false"
  }

  assert {
    condition     = aws_cloudwatch_dashboard.observability.dashboard_name == "test-observability"
    error_message = "expected dashboard to exist even when alarms are disabled"
  }
}
