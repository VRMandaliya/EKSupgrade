module "wildcard_com" {
  source  = "voquis/acm-dns-validation/aws"
  version = "0.0.3"

  zone_id     = "Z02016961RWF2K0YLR4P"
  domain_name = "syzygy-ai.com"
  subject_alternative_names = [
    "*.syzygy-ai.com"
  ]
}
