# Example DNS record using Route53.
# Route53 is not specifically required; any DNS host can be used.
resource "aws_route53_record" "vat_erpware_co" {
  name    = aws_api_gateway_domain_name.vat_erpware_co.domain_name
  type    = "A"
  zone_id = data.aws_route53_zone.erpware_co.zone_id

  alias {
    evaluate_target_health = true
    name                   = aws_api_gateway_domain_name.vat_erpware_co.regional_domain_name
    zone_id                = aws_api_gateway_domain_name.vat_erpware_co.regional_zone_id
  }
}