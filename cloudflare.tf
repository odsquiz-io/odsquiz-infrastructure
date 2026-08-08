# Keep records DNS-only while Google provisions its managed certificate. Once
# the certificate is ACTIVE, proxying can be enabled deliberately if desired.
resource "cloudflare_dns_record" "custom_domain" {
  for_each = var.cloudflare_zone_id == null ? toset([]) : toset(var.custom_domains)

  zone_id = var.cloudflare_zone_id
  name    = each.value
  type    = "A"
  content = google_compute_global_address.odsquiz_lb.address
  ttl     = 1
  proxied = false
  comment = "Managed by Terraform: ODS Quiz external load balancer"
}
