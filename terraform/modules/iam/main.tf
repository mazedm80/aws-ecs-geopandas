resource "aws_iam_user" "ecr-user" {
  name = "ecs-demo-user"
  path = "/system/"

  tags = {
        name = "ECS Demo-${var.env}"
        environment = var.env
    }
}

resource "aws_iam_access_key" "ecr-user" {
  user = aws_iam_user.ecr-user.name
}

data "aws_iam_policy_document" "ecr-user" {
  statement {
    effect    = "Allow"
    actions   = [
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:GetRepositoryPolicy",
        "ecr:DescribeRepositories",
        "ecr:ListImages",
        "ecr:DescribeImages",
        "ecr:BatchGetImage",
        "ecr:GetLifecyclePolicy",
        "ecr:GetLifecyclePolicyPreview",
        "ecr:ListTagsForResource",
        "ecr:DescribeImageScanFindings"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_user_policy" "ecr-user" {
  name   = "ECS-Demo-ECR-User-Policy"
  user   = aws_iam_user.ecr-user.name
  policy = data.aws_iam_policy_document.ecr-user.json
}

variable "env" {
    description = "Deployment environment"
    type = string
}

output "ecr_user_access_key_id" {
  value = aws_iam_access_key.ecr-user.id
  sensitive = true
}

output "ecr_user_secret_access_key" {
  value = aws_iam_access_key.ecr-user.secret
  sensitive = true
}