locals {
  databricks_role_name            = "puc-databricks-cluster-role"
  databricks_instance_profile     = "puc-databricks-cluster-profile"
  databricks_s3_policy_name       = "puc-databricks-s3-access"
}

resource "aws_iam_role" "databricks_cluster_role" {
  name               = local.databricks_role_name
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = { Service = "ec2.amazonaws.com" },
      Action   = "sts:AssumeRole"
    }]
  })
  tags = {
    project = "databricks-ml"
    layer   = "infra"
  }
}

resource "aws_iam_role_policy" "databricks_cluster_s3_access" {
  name = local.databricks_s3_policy_name
  role = aws_iam_role.databricks_cluster_role.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = [
          "s3:ListBucket",
          "s3:GetBucketLocation",
          "s3:ListBucketMultipartUploads"
        ],
        Resource = aws_s3_bucket.lake.arn
      },
      {
        Effect   = "Allow",
        Action   = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:AbortMultipartUpload",
          "s3:ListMultipartUploadParts",
          "s3:CreateMultipartUpload",
          "s3:CompleteMultipartUpload"
        ],
        Resource = "${aws_s3_bucket.lake.arn}/*"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "databricks_cluster" {
  name = local.databricks_instance_profile
  role = aws_iam_role.databricks_cluster_role.name
}

resource "databricks_instance_profile" "cluster_profile" {
  instance_profile_arn = aws_iam_instance_profile.databricks_cluster.arn
  skip_validation      = true
}

## Opcional: conceder iam:PassRole para a role do workspace Databricks
variable "databricks_cross_account_role_name" {
  type        = string
  description = "Nome da role que o workspace Databricks utiliza (para conceder iam:PassRole ao instance profile). Deixe vazio para não anexar."
  default     = ""
}

resource "aws_iam_role_policy" "allow_passrole_to_instance_profile" {
  count = var.databricks_cross_account_role_name != "" ? 1 : 0
  name  = "allow-passrole-to-databricks-instance-profile"
  role  = var.databricks_cross_account_role_name
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = ["iam:PassRole"],
        Resource = aws_iam_role.databricks_cluster_role.arn,
        Condition = {
          StringEquals = { "iam:PassedToService": "ec2.amazonaws.com" }
        }
      }
    ]
  })
}
