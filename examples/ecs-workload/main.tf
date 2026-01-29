data "terraform_remote_state" "platform" {
  backend = "s3"

  config = {
    bucket = var.state_bucket
    key    = local.state_key
    region = local.state_region
  }
}

resource "terraform_data" "platform_guard" {
  input = data.terraform_remote_state.platform.outputs.platform

  lifecycle {
    precondition {
      condition     = data.terraform_remote_state.platform.outputs.platform == "ecs"
      error_message = "This example requires platform = \"ecs\" in the environment state."
    }
  }
}

data "aws_ecs_cluster" "platform" {
  cluster_name = data.terraform_remote_state.platform.outputs.ecs_cluster_name
}

data "aws_lb_target_group" "platform" {
  arn = data.terraform_remote_state.platform.outputs.target_group_arn
}

data "aws_cloudwatch_log_group" "ecs" {
  name = "/aws/ecs/${local.name_prefix}"
}

data "aws_iam_role" "task_execution" {
  name = "${local.name_prefix}-ecs-exec"
}

data "aws_iam_role" "task" {
  name = "${local.name_prefix}-ecs-task"
}

resource "aws_ecs_task_definition" "example" {
  family                   = "${local.name_prefix}-example-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = data.aws_iam_role.task_execution.arn
  task_role_arn            = data.aws_iam_role.task.arn

  container_definitions = jsonencode([
    {
      name      = "app"
      image     = local.container_image
      essential = true
      portMappings = [
        {
          containerPort = local.container_port
          hostPort      = local.container_port
          protocol      = "tcp"
        }
      ]
      environment = local.environment_list
      secrets     = local.secrets_list
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = data.aws_cloudwatch_log_group.ecs.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "example"
        }
      }
      user                   = "1000"
      readonlyRootFilesystem = false
    }
  ])

  tags = local.tags
}

resource "aws_ecs_service" "example" {
  name            = "${local.name_prefix}-example-svc"
  cluster         = data.aws_ecs_cluster.platform.arn
  task_definition = aws_ecs_task_definition.example.arn
  desired_count   = var.desired_count

  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200
  health_check_grace_period_seconds  = 60

  enable_execute_command = true

  network_configuration {
    subnets          = data.terraform_remote_state.platform.outputs.private_subnet_ids
    security_groups  = [data.terraform_remote_state.platform.outputs.compute_sg_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = data.terraform_remote_state.platform.outputs.target_group_arn
    container_name   = "app"
    container_port   = local.container_port
  }

  tags = local.tags

  depends_on = [terraform_data.platform_guard]
}
