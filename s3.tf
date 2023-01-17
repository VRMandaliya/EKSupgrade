module "terraform-state" {
  version = "2.13.0"
  source  = "terraform-aws-modules/s3-bucket/aws"

  bucket = "mm-clean-terraform-state"
  acl    = "private"

  versioning = {
    enabled = true
  }
}

module "clean-me-s3" {
  version = "2.13.0"
  source  = "terraform-aws-modules/s3-bucket/aws"

  bucket                  = local.name
  acl                     = "private"
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
  attach_policy           = true
  policy                  = <<EOF
{
    "Version": "2008-10-17",
    "Id": "PolicyForCloudFrontPrivateContent",
    "Statement": [
        {
            "Sid": "1",
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::cloudfront:user/CloudFront Origin Access Identity E2H0DFQ6K06TTI"
            },
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::clean-me/users/*"
        }
    ]
}
EOF
}

module "syzygy-ai-s3" {
  version = "2.13.0"
  source  = "terraform-aws-modules/s3-bucket/aws"

  bucket = "syzygy-ai.com"
  acl    = "private"

  website = {
    error_document = "error.html"
    index_document = "index.html"
  }
}

module "www-syzygy-ai-s3" {
  version = "2.13.0"
  source  = "terraform-aws-modules/s3-bucket/aws"

  bucket = "www.syzygy-ai.com"
  acl    = "private"

  website = {
    redirect_all_requests_to = "syzygy-ai.com"
  }
}

module "syzygy-ai-2-s3" {
  version = "2.13.0"
  source  = "terraform-aws-modules/s3-bucket/aws"

  bucket               = "syzygy-ai"
  attach_public_policy = false
}

module "syzygy-media-s3" {
  version = "2.13.0"
  source  = "terraform-aws-modules/s3-bucket/aws"

  bucket               = "syzygy-media"
  attach_public_policy = false
}

module "syzygy-ai-secrets-s3" {
  version = "2.13.0"
  providers = {
    aws = aws.stockholm
  }
  source = "terraform-aws-modules/s3-bucket/aws"

  bucket                  = "syzygy-ai-secrets"
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
  object_ownership        = "BucketOwnerEnforced"

}

module "clean-me-dump" {
  version = "2.13.0"
  source  = "terraform-aws-modules/s3-bucket/aws"

  bucket = "clean-me-dump"
  acl    = "private"

  lifecycle_rule = [
    {
      id                                     = "dump"
      enabled                                = true
      abort_incomplete_multipart_upload_days = 14

      expiration = {
        days                         = 14
        expired_object_delete_marker = false
      }

      noncurrent_version_expiration = {
        days = 14
      }
    },
  ]
}

module "clean-me-vault" {
  version = "2.13.0"
  source  = "terraform-aws-modules/s3-bucket/aws"

  bucket = "clean-me-vault"
  acl    = "private"

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  server_side_encryption_configuration = {
    rule = {
      bucket_key_enabled = false

      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }
}

module "clean-me-syzygy-ai-s3" {
  version = "2.13.0"
  source  = "terraform-aws-modules/s3-bucket/aws"

  bucket = "clean-me.syzygy-ai.com"
  acl    = "private"

  website = {
    error_document = "error.html"
    index_document = "index.html"
  }

  attach_policy = true
  policy        = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "PublicReadGetObject",
            "Effect": "Allow",
            "Principal": "*",
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::clean-me.syzygy-ai.com/*"
        }
    ]
}
EOF
}

module "www-clean-me-syzygy-ai-s3" {
  version = "2.13.0"
  source  = "terraform-aws-modules/s3-bucket/aws"

  bucket = "www.clean-me.syzygy-ai.com"
  acl    = "private"

  website = {
    redirect_all_requests_to = "clean-me.syzygy-ai.com"
  }
}

module "clean-me-e2e-s3" {
  version = "2.13.0"
  source  = "terraform-aws-modules/s3-bucket/aws"

  bucket                  = "clean-me-e2e"
  acl                     = "private"
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
  policy                  = <<EOF
{
    "Version": "2008-10-17",
    "Id": "PolicyForCloudFrontPrivateContent",
    "Statement": [
        {
            "Sid": "1",
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::cloudfront:user/CloudFront Origin Access Identity E2H0DFQ6K06TTI"
            },
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::clean-me-e2e/users/*"
        }
    ]
}
EOF
}

module "syzygy-ai-de-s3" {
  version = "2.13.0"
  source  = "terraform-aws-modules/s3-bucket/aws"

  bucket = "syzygy-ai-gmbh.de"
  acl    = "private"

  website = {
    error_document = "error.html"
    index_document = "index.html"
  }

  attach_policy = true
  policy        = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "PublicReadGetObject",
            "Effect": "Allow",
            "Principal": "*",
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::syzygy-ai-gmbh.de/*"
        }
    ]
}
EOF
}

module "www-syzygy-ai-de-s3" {
  version = "2.13.0"
  source  = "terraform-aws-modules/s3-bucket/aws"

  bucket = "www.syzygy-ai-gmbh.de"
  acl    = "private"

  website = {
    redirect_all_requests_to = "syzygy-ai-gmbh.de"
  }
}

module "smart-mirror-syzygy-ai-s3" {
  version = "2.13.0"
  source  = "terraform-aws-modules/s3-bucket/aws"

  bucket = "smart-mirror.syzygy-ai.com"
  acl    = "private"

  website = {
    error_document = "error.html"
    index_document = "index.html"
  }

  attach_policy = true
  policy        = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "PublicReadGetObject",
            "Effect": "Allow",
            "Principal": "*",
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::smart-mirror.syzygy-ai.com/*"
        }
    ]
}
EOF
}

module "cleanbee-syzygy-ai-s3" {
  version = "2.13.0"
  source  = "terraform-aws-modules/s3-bucket/aws"

  bucket = "cleanbee.syzygy-ai.com"
  acl    = "private"

  website = {
    error_document = "error.html"
    index_document = "index.html"
  }

  attach_policy = true
  policy        = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "PublicReadGetObject",
            "Effect": "Allow",
            "Principal": "*",
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::cleanbee.syzygy-ai.com/*"
        }
    ]
}
EOF
}

module "clean-me-staging-s3" {
  version = "2.13.0"
  source  = "terraform-aws-modules/s3-bucket/aws"

  bucket                  = "clean-me-staging"
  acl                     = "private"
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

module "syzygy-ai-repository-s3" {
  version = "2.13.0"
  source  = "terraform-aws-modules/s3-bucket/aws"

  bucket                  = "syzygy-ai-repository"
  acl                     = "private"
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
