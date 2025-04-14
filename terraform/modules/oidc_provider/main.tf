resource "aws_iam_openid_connect_provider" "nomad" {
  url             = var.api_url
  client_id_list  = ["${var.api_url}"]
  tags = {
    Name = var.provider_name
  }
}
# IAM Role for OIDC - Example role with policy
resource "aws_iam_role" "nomad_workload" {
  name = "nomad-workload-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Federated = aws_iam_openid_connect_provider.nomad.arn
        },
        Action = "sts:AssumeRoleWithWebIdentity",
        Condition = {
          StringEquals = {
            "${replace(var.api_url, "https://", "")}:aud" : "nomad"
          }
        }
      }
    ]
  })

  tags = {
    Name = "nomad-workload-role"
  }
}

# Example policy attachment
resource "aws_iam_role_policy_attachment" "nomad_s3_access" {
  role       = aws_iam_role.nomad_workload.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}
