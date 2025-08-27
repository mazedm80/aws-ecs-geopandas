resource "aws_ecr_repository" "geopandas-demo" {
    name                 = "geopandas-demo-${var.env}"
    image_tag_mutability = "MUTABLE"
    encryption_configuration {
    encryption_type = "AES256"
    }
    image_scanning_configuration {
    scan_on_push = true
    }
    tags = {
        name = "Geopandas Demo-${var.env}"
        environment = var.env
    }
}

resource "aws_ecr_lifecycle_policy" "example" {
  repository = aws_ecr_repository.geopandas-demo.name

  policy = <<EOF
{
    "rules": [
        {
            "rulePriority": 1,
            "description": "Expire untagged images older than 14 days",
            "selection": {
                "tagStatus": "untagged",
                "countType": "sinceImagePushed",
                "countUnit": "days",
                "countNumber": 14
            },
            "action": {
                "type": "expire"
            }
        }
    ]
}
EOF
}

variable "env" {
    description = "Deployment environment"
    type        = string
}