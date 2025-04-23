# This file contains the S3 bucket resource and its configuration.
resource "random_string" "bucket_suffix" {
  length  = 4   # Length of the random string
  upper   = false
  lower   = true
  numeric  = true
  special = false
}
resource "aws_s3_bucket" "default" {
  bucket        = "web-app-${random_string.bucket_suffix.result}"
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "default" {
  bucket = aws_s3_bucket.default.bucket
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "default" {
  bucket = aws_s3_bucket.default.bucket
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "default" {
  bucket = aws_s3_bucket.default.bucket

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "default" {
  bucket = aws_s3_bucket.default.id
  policy = data.aws_iam_policy_document.s3_bucket_policy.json
  depends_on = [aws_s3_bucket.default
    , aws_s3_bucket_server_side_encryption_configuration.default
    , aws_s3_bucket_public_access_block.default
  ]
}

data "aws_iam_policy_document" "s3_bucket_policy" {
  depends_on = [aws_cloudfront_distribution.web_app]
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.default.arn}/*"]
    effect    = "Allow"
    condition   {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = ["${aws_cloudfront_distribution.web_app.arn}"]
    }
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }
  }
}