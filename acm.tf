resource "aws_acm_certificate" "vat_erpware_co" {
  domain_name       = "vat.erpware.co"
  validation_method = "DNS"
}

resource "aws_route53_record" "vat_erpware_co_acm" {
  for_each = {
    for dvo in aws_acm_certificate.vat_erpware_co.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.erpware_co.zone_id
}

resource "aws_acm_certificate_validation" "vat_erpware_co" {
  certificate_arn         = aws_acm_certificate.vat_erpware_co.arn
  validation_record_fqdns = [for record in aws_route53_record.vat_erpware_co_acm : record.fqdn]
}

