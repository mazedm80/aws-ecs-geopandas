# EventBridge Scheduler Role
data "aws_iam_policy_document" "eventbridge_scheduler_role_policy" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["scheduler.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "eventbridge_scheduler_role" {
  name = "EventBridgeSchedulerRole"
  assume_role_policy = data.aws_iam_policy_document.eventbridge_scheduler_role_policy.json
}

resource "aws_iam_role_policy" "scheduler" {
  name = "CronSchedulerPolicy"
  role = aws_iam_role.eventbridge_scheduler_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ecs:RunTask"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "iam:PassRole"
        ]
        Resource = "*"
      },
    ]
  })
}