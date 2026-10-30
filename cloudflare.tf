locals {
  # Deterministic Cloud Run URLs stay the same when the services are destroyed
  # and recreated, so the Worker does not depend on the billable resources.
  run_url_suffix = "${data.google_project.current.number}.${var.region}.run.app"

  worker_origins = {
    AUTH_ORIGIN        = "https://${var.auth_service_name}-${local.run_url_suffix}"
    INITIATIVES_ORIGIN = "https://${var.initiatives_service_name}-${local.run_url_suffix}"
    QUIZ_ORIGIN        = "https://${var.quiz_service_name}-${local.run_url_suffix}"
    ADMIN_ORIGIN       = "https://${var.admin_service_name}-${local.run_url_suffix}"
    FRONTEND_ORIGIN    = "https://${var.frontend_service_name}-${local.run_url_suffix}"
  }

  cloudflare_domains = var.cloudflare_zone_id == null || var.cloudflare_account_id == null ? toset([]) : toset(var.custom_domains)
}

data "google_project" "current" {}

resource "cloudflare_workers_script" "router" {
  count = var.cloudflare_account_id == null ? 0 : 1

  account_id         = var.cloudflare_account_id
  script_name        = "odsquiz-router"
  main_module        = "router.js"
  content_file       = "${path.module}/worker/router.js"
  content_sha256     = filesha256("${path.module}/worker/router.js")
  compatibility_date = "2026-10-01"

  bindings = [
    for name, origin in local.worker_origins : {
      name = name
      type = "plain_text"
      text = origin
    }
  ]
}

# Workers routes need a proxied record; 100:: is the documented placeholder for
# hostnames whose requests are answered entirely by a Worker.
resource "cloudflare_dns_record" "custom_domain" {
  for_each = local.cloudflare_domains

  zone_id = var.cloudflare_zone_id
  name    = each.value
  type    = "AAAA"
  content = "100::"
  ttl     = 1
  proxied = true
  comment = "Managed by Terraform: ODS Quiz router Worker"
}

resource "cloudflare_workers_route" "router" {
  for_each = local.cloudflare_domains

  zone_id = var.cloudflare_zone_id
  pattern = "${each.value}/*"
  script  = cloudflare_workers_script.router[0].script_name
}
