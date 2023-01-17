module "syzygy-ai-domain" {
  source = "terraform-aws-modules/route53/aws//modules/records"

  zone_id = data.aws_route53_zone.zone_syzygy_ai.zone_id

  records = [
    {
      name = ""
      type = "A"
      alias = {
        name    = module.syzygy-ai.cloudfront_distribution_domain_name
        zone_id = module.syzygy-ai.cloudfront_distribution_hosted_zone_id
      }
    },
  ]
}

module "clean-me-subdomain" {
  source = "terraform-aws-modules/route53/aws//modules/records"

  zone_id = data.aws_route53_zone.zone_syzygy_ai.zone_id

  records = [
    {
      name = local.subdomain
      type = "A"
      alias = {
        name    = module.clean-me-syzygy-ai.cloudfront_distribution_domain_name
        zone_id = module.clean-me-syzygy-ai.cloudfront_distribution_hosted_zone_id
      }
    },
    {
      name = "www.${local.subdomain}"
      type = "A"
      alias = {
        name    = module.clean-me-syzygy-ai.cloudfront_distribution_domain_name
        zone_id = module.clean-me-syzygy-ai.cloudfront_distribution_hosted_zone_id
      }
    },
  ]
}

module "smart-mirror-subdomain" {
  source = "terraform-aws-modules/route53/aws//modules/records"

  zone_id = data.aws_route53_zone.zone_syzygy_ai.zone_id

  records = [
    {
      name = "smart-mirror"
      type = "A"
      alias = {
        name    = module.smart-mirror-syzygy-ai.cloudfront_distribution_domain_name
        zone_id = module.smart-mirror-syzygy-ai.cloudfront_distribution_hosted_zone_id
      }
    },
    {
      name = "www.smart-mirror"
      type = "A"
      alias = {
        name    = module.smart-mirror-syzygy-ai.cloudfront_distribution_domain_name
        zone_id = module.smart-mirror-syzygy-ai.cloudfront_distribution_hosted_zone_id
      }
    },
  ]
}

module "syzygy-ai-gmbh-de-subdomain" {
  source = "terraform-aws-modules/route53/aws//modules/records"

  zone_id = data.aws_route53_zone.zone_syzygy_ai_gmbh_de.zone_id

  records = [
    {
      name = ""
      type = "A"
      alias = {
        name    = module.syzygy-ai-gmbh-de.cloudfront_distribution_domain_name
        zone_id = module.syzygy-ai-gmbh-de.cloudfront_distribution_hosted_zone_id
      }
    },
    {
      name = "www"
      type = "A"
      alias = {
        name    = module.syzygy-ai-gmbh-de.cloudfront_distribution_domain_name
        zone_id = module.syzygy-ai-gmbh-de.cloudfront_distribution_hosted_zone_id
      }
    },
  ]
}

resource "aws_route53_record" "opensearch-custom-domain" {

  zone_id = data.aws_route53_zone.zone_syzygy_ai.zone_id
  name    = "opensearch"
  type    = "CNAME"
  records = ["vpc-clean-me-imuvhmatyvxdpwtf3rmhuyrc5q.eu-west-1.es.amazonaws.com"]
  ttl     = 300
}

module "cleanbee-subdomain" {
  source = "terraform-aws-modules/route53/aws//modules/records"

  zone_id = data.aws_route53_zone.zone_syzygy_ai.zone_id

  records = [
    {
      name = "cleanbee"
      type = "A"
      alias = {
        name    = module.cleanbee-syzygy-ai.cloudfront_distribution_domain_name
        zone_id = module.cleanbee-syzygy-ai.cloudfront_distribution_hosted_zone_id
      }
    },
    {
      name = "www.cleanbee"
      type = "A"
      alias = {
        name    = module.cleanbee-syzygy-ai.cloudfront_distribution_domain_name
        zone_id = module.cleanbee-syzygy-ai.cloudfront_distribution_hosted_zone_id
      }
    },
  ]
}
