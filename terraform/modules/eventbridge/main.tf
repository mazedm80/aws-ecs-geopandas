data "aws_subnets" "current" {}
data "aws_security_group" "current" {}

resource "aws_scheduler_schedule_group" "ecs" {
  name = "ecs-jobs"

  tags = {
    Name        = "ecs-jobs-${var.env}"
    Environment = var.env
  }
}

resource "aws_scheduler_schedule" "geopandas_demo" {
  name       = "geopandas-demo-${var.env}-schedule"
  group_name = aws_scheduler_schedule_group.ecs.name

  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression = "cron(0 12 * * ? *)"

  target {
    arn      = var.ecs_cluster_arn
    role_arn = aws_iam_role.eventbridge_scheduler_role.arn

    ecs_parameters {
      task_definition_arn = var.ecs_task_definition_arn
      task_count = 1
      launch_type = "FARGATE"
      network_configuration {
        subnets          = data.aws_subnets.current.ids
        security_groups  = [data.aws_security_group.current.id]
        assign_public_ip = true
      }
    }
  }

  depends_on = [ var.event_bridge_depends_on ]
}

variable "env" {
    description = "Deployment environment"
    type        = string
}

variable "ecs_cluster_arn" {
    description = "ARN of the ECS cluster"
    type        = string
}

variable "ecs_task_definition_arn" {
    description = "ARN of the ECS task definition"
    type        = string
}

variable "event_bridge_depends_on" {
    description = "Dependencies for EventBridge module"
    type        = any
}