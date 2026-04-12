data "aws_iam_policy_document" "sample_app" {
  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:ListBucket"
    ]
    resources = [
      "arn:aws:s3:::dev-platform-tfstate-375976227140",
      "arn:aws:s3:::dev-platform-tfstate-375976227140/*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "rds-db:connect"
    ]
    resources = [
      "arn:aws:rds-db:*:*:dbuser:*/sampleapp"
    ]
  }
}

resource "aws_iam_policy" "sample_app" {
  name        = "${var.project_name}-${var.environment}-sample-app"
  description = "Least-privilege policy for sample-app pods"
  policy      = data.aws_iam_policy_document.sample_app.json
}

resource "aws_iam_role" "sample_app" {
  name = "${var.project_name}-${var.environment}-sample-app"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = module.eks.oidc_provider_arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${module.eks.oidc_provider}:sub" = "system:serviceaccount:default:sample-app"
          "${module.eks.oidc_provider}:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "sample_app" {
  role       = aws_iam_role.sample_app.name
  policy_arn = aws_iam_policy.sample_app.arn
}

output "sample_app_role_arn" {
  value = aws_iam_role.sample_app.arn
}
