data "aws_caller_identity" "current" {}
# Create an S3 bucket for Redshift Serverless integration with SSM
resource "aws_s3_bucket" "ecs-demo" {
    bucket = "ecs-demo-${var.env}-bucket-${random_id.suffix.hex}"
    tags = {
        name = "ECS Demo-${var.env}"
        environment = var.env
    }
    force_destroy = true
}

resource "random_id" "suffix" {
    byte_length = 4
}

variable "env" {
    description = "Deployment environment"
    type = string
}

output "bucket_arn" {
  value = aws_s3_bucket.ecs-demo.arn
}