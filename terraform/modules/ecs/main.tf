resource "aws_ecs_cluster" "geopandas_demo" {
  name = "geopandas-demo-${var.env}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_ecs_task_definition" "service" {
  family                   = "geopandas-demo-${var.env}-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = var.container_name
      image     = var.container_url
      essential = true
      environment = [
        { name = "DATA_DIR", value = "/data/" },
        { name = "GADM_FILE_NAME", value = "gadm41_DEU_4.json" },
        { name = "RASTER_FILE_NAME", value = "DEU_wind-speed_10m.tif" },
        { name = "BUCKET_NAME", value = var.bucket_name }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/ecs-demo-task"
          awslogs-create-group  = "true",
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])

  tags = {
    Name        = "geopandas-demo-${var.env}-task"
    Environment = var.env
  }

  depends_on = [ var.ecs_depends_on ]
}

variable "env" {
    description = "Deployment environment"
    type        = string
}

variable "aws_region" {
    description = "AWS region to deploy resources"
    type        = string  
}

variable "bucket_name" {
    description = "Name of the S3 bucket"
    type        = string
}

variable "ecs_depends_on" {
    description = "Dependencies for ECS module"
    type        = any
}

variable "bucket_arn" {
    description = "ARN of the S3 bucket"
    type        = string
}

variable "container_name" {
    description = "Name of the container"
    type        = string
}

variable "container_url" {
    description = "URL of the container"
    type        = string
}