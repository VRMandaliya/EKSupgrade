locals {
  domain_name = "syzygy-ai.com"
  subdomain   = "clean-me"
}

module "syzygy-ai" {
  source  = "terraform-aws-modules/cloudfront/aws"
  version = "2.9.2"

  aliases             = ["${local.domain_name}", "www.${local.domain_name}"]
  enabled             = true
  is_ipv6_enabled     = true
  price_class         = "PriceClass_All"
  retain_on_delete    = false
  wait_for_deployment = true
  create_distribution = true

  create_origin_access_identity = false

  origin = {
    syzygy-ai = {
      connection_attempts = 3
      connection_timeout  = 10
      domain_name         = "syzygy-ai.com.s3-website-eu-west-1.amazonaws.com"
      origin_id           = "syzygy-ai.com.s3.eu-west-1.amazonaws.com"

      custom_origin_config = {
        http_port                = 80
        https_port               = 443
        origin_keepalive_timeout = 5
        origin_protocol_policy   = "http-only"
        origin_read_timeout      = 30
        origin_ssl_protocols = [
          "TLSv1",
          "TLSv1.1",
          "TLSv1.2",
        ]
      }
    }
  }

  default_cache_behavior = {
    cache_policy_id        = "658327ea-f89d-4fab-a63d-7e88639e58f6"
    target_origin_id       = module.syzygy-ai-s3.s3_bucket_bucket_regional_domain_name
    viewer_protocol_policy = "redirect-to-https"
    use_forwarded_values   = false

    allowed_methods = ["GET", "HEAD"]
    cached_methods  = ["GET", "HEAD"]
    compress        = true
    query_string    = true
  }

  viewer_certificate = {
    acm_certificate_arn      = "arn:aws:acm:us-east-1:620428644349:certificate/a7ac830f-13d6-4770-a6b9-39e4d3d59d41"
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

}

module "clean-me-syzygy-ai" {
  source  = "terraform-aws-modules/cloudfront/aws"
  version = "2.9.2"

  aliases             = ["${local.subdomain}.${local.domain_name}", "www.${local.subdomain}.${local.domain_name}"]
  enabled             = true
  is_ipv6_enabled     = true
  price_class         = "PriceClass_All"
  retain_on_delete    = false
  wait_for_deployment = true
  create_distribution = true

  create_origin_access_identity = true
  origin_access_identities = {
    s3_clean-me = "clean-me S3"
  }

  origin = {
    clean-me-syzygy-ai = {
      connection_attempts = 3
      connection_timeout  = 10
      domain_name         = "clean-me.syzygy-ai.com.s3-website-eu-west-1.amazonaws.com"
      origin_id           = "clean-me.syzygy-ai.com.s3.eu-west-1.amazonaws.com"

      custom_origin_config = {
        http_port                = 80
        https_port               = 443
        origin_keepalive_timeout = 5
        origin_protocol_policy   = "http-only"
        origin_read_timeout      = 30
        origin_ssl_protocols = [
          "TLSv1",
          "TLSv1.1",
          "TLSv1.2",
        ]
      }
    }

    "clean-me.s3.eu-west-1.amazonaws.com" = {
      domain_name = module.clean-me-s3.s3_bucket_bucket_regional_domain_name
      s3_origin_config = {
        origin_access_identity = "s3_clean-me"
      }
    }

    "clean-me-staging.s3.eu-west-1.amazonaws.com" = {
      domain_name = module.clean-me-staging-s3.s3_bucket_bucket_regional_domain_name
      s3_origin_config = {
        origin_access_identity = "s3_clean-me"
      }
    }

    "clean-me-e2e.s3.eu-west-1.amazonaws.com" = {
      domain_name = module.clean-me-e2e-s3.s3_bucket_bucket_regional_domain_name
      s3_origin_config = {
        origin_access_identity = "s3_clean-me"
      }
    }

  }

  default_cache_behavior = {
    target_origin_id       = module.clean-me-syzygy-ai-s3.s3_bucket_bucket_regional_domain_name
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["GET", "HEAD"]
    cached_methods  = ["GET", "HEAD"]
    compress        = true
    query_string    = true
  }

  ordered_cache_behavior = [
    {
      path_pattern           = "/clean-me/users/*"
      target_origin_id       = "clean-me.s3.eu-west-1.amazonaws.com"
      viewer_protocol_policy = "redirect-to-https"

      allowed_methods = ["GET", "HEAD"]
      cached_methods  = ["GET", "HEAD"]
      compress        = true
      query_string    = true

      function_association = {
        viewer-request = {
          function_arn = aws_cloudfront_function.shrink_path.arn
        }
      }

      forwarded_values = {
        query_string            = true
        query_string_cache_keys = []

        cookies = {
          forward = "none"
        }
      }
    },
    {
      path_pattern           = "/clean-me-staging/users/*"
      target_origin_id       = "clean-me-staging.s3.eu-west-1.amazonaws.com"
      viewer_protocol_policy = "redirect-to-https"

      allowed_methods = ["GET", "HEAD"]
      cached_methods  = ["GET", "HEAD"]
      compress        = true
      query_string    = true

      function_association = {
        viewer-request = {
          function_arn = aws_cloudfront_function.shrink_path.arn
        }
      }

      forwarded_values = {
        query_string            = true
        query_string_cache_keys = []

        cookies = {
          forward = "none"
        }
      }
    },
    {
      path_pattern           = "/clean-me-e2e/users/*"
      target_origin_id       = "clean-me-e2e.s3.eu-west-1.amazonaws.com"
      viewer_protocol_policy = "redirect-to-https"

      allowed_methods = ["GET", "HEAD"]
      cached_methods  = ["GET", "HEAD"]
      compress        = true
      query_string    = true

      function_association = {
        viewer-request = {
          function_arn = aws_cloudfront_function.shrink_path.arn
        }
      }

      forwarded_values = {
        query_string            = true
        query_string_cache_keys = []

        cookies = {
          forward = "none"
        }
      }
    }

  ]

  viewer_certificate = {
    acm_certificate_arn      = "arn:aws:acm:us-east-1:620428644349:certificate/b2c927fb-6b51-4660-8f2d-a68d7d024845"
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

}

resource "aws_cloudfront_function" "shrink_path" {
  name    = "shrink_path"
  runtime = "cloudfront-js-1.0"
  code    = file("scripts/shrink_path-function.js")
}

module "syzygy-ai-gmbh-de" {
  source  = "terraform-aws-modules/cloudfront/aws"
  version = "2.9.2"

  aliases             = ["syzygy-ai-gmbh.de", "www.syzygy-ai-gmbh.de"]
  enabled             = true
  is_ipv6_enabled     = true
  price_class         = "PriceClass_All"
  retain_on_delete    = false
  wait_for_deployment = true
  create_distribution = true

  create_origin_access_identity = true

  origin = {
    syzygy-ai-gmbh-de = {
      connection_attempts = 3
      connection_timeout  = 10
      domain_name         = "syzygy-ai-gmbh.de.s3-website-eu-west-1.amazonaws.com"
      origin_id           = "syzygy-ai-gmbh.de.s3.eu-west-1.amazonaws.com"

      custom_origin_config = {
        http_port                = 80
        https_port               = 443
        origin_keepalive_timeout = 5
        origin_protocol_policy   = "http-only"
        origin_read_timeout      = 30
        origin_ssl_protocols = [
          "TLSv1",
          "TLSv1.1",
          "TLSv1.2",
        ]
      }
    }
  }

  default_cache_behavior = {
    target_origin_id       = module.syzygy-ai-de-s3.s3_bucket_bucket_regional_domain_name
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["GET", "HEAD"]
    cached_methods  = ["GET", "HEAD"]
    compress        = true
    query_string    = true
  }

  viewer_certificate = {
    acm_certificate_arn      = "arn:aws:acm:us-east-1:620428644349:certificate/6fa58225-d1f5-4be9-a7d1-7aba9b96ab73"
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

}

module "smart-mirror-syzygy-ai" {
  source  = "terraform-aws-modules/cloudfront/aws"
  version = "2.9.2"

  aliases             = ["smart-mirror.${local.domain_name}", "www.smart-mirror.${local.domain_name}"]
  enabled             = true
  is_ipv6_enabled     = true
  price_class         = "PriceClass_All"
  retain_on_delete    = false
  wait_for_deployment = true
  create_distribution = true

  create_origin_access_identity = true

  origin = {
    syzygy-ai-gmbh-de = {
      connection_attempts = 3
      connection_timeout  = 10
      domain_name         = "smart-mirror.syzygy-ai.com.s3-website-eu-west-1.amazonaws.com"
      origin_id           = "smart-mirror.syzygy-ai.com.s3.eu-west-1.amazonaws.com"

      custom_origin_config = {
        http_port                = 80
        https_port               = 443
        origin_keepalive_timeout = 5
        origin_protocol_policy   = "http-only"
        origin_read_timeout      = 30
        origin_ssl_protocols = [
          "TLSv1",
          "TLSv1.1",
          "TLSv1.2",
        ]
      }
    }
  }

  default_cache_behavior = {
    target_origin_id       = module.smart-mirror-syzygy-ai-s3.s3_bucket_bucket_regional_domain_name
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["GET", "HEAD"]
    cached_methods  = ["GET", "HEAD"]
    compress        = true
    query_string    = true
  }

  viewer_certificate = {
    acm_certificate_arn      = "arn:aws:acm:us-east-1:620428644349:certificate/6d002dca-b869-4530-9e55-6e168f4c017e"
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

}

module "cleanbee-syzygy-ai" {
  source  = "terraform-aws-modules/cloudfront/aws"
  version = "2.9.2"

  aliases             = ["cleanbee.${local.domain_name}", "www.cleanbee.${local.domain_name}"]
  enabled             = true
  is_ipv6_enabled     = true
  price_class         = "PriceClass_All"
  retain_on_delete    = false
  wait_for_deployment = true
  create_distribution = true

  create_origin_access_identity = true

  origin = {
    cleanbee-syzygy-ai = {
      connection_attempts = 3
      connection_timeout  = 10
      domain_name         = "cleanbee.syzygy-ai.com.s3-website-eu-west-1.amazonaws.com"
      origin_id           = "cleanbee.syzygy-ai.com.s3.eu-west-1.amazonaws.com"

      custom_origin_config = {
        http_port                = 80
        https_port               = 443
        origin_keepalive_timeout = 5
        origin_protocol_policy   = "http-only"
        origin_read_timeout      = 30
        origin_ssl_protocols = [
          "TLSv1",
          "TLSv1.1",
          "TLSv1.2",
        ]
      }
    }
  }

  default_cache_behavior = {
    target_origin_id       = module.cleanbee-syzygy-ai-s3.s3_bucket_bucket_regional_domain_name
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["GET", "HEAD"]
    cached_methods  = ["GET", "HEAD"]
    compress        = true
    query_string    = true
  }

  viewer_certificate = {
    acm_certificate_arn      = "arn:aws:acm:us-east-1:620428644349:certificate/0520798f-1962-4978-b1fc-69a47110e321"
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

}
