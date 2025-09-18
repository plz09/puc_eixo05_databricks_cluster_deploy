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
        Action   = ["s3:ListBucket"],
        Resource = aws_s3_bucket.lake.arn
      },
      {
        Effect   = "Allow",
        Action   = ["s3:GetObject","s3:PutObject","s3:DeleteObject"],
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
}
