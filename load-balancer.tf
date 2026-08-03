resource "google_compute_global_address" "odsquiz_lb" {
  name = "odsquiz-lb-ip"

  depends_on = [google_project_service.compute]
}

resource "google_compute_region_network_endpoint_group" "frontend" {
  name                  = "odsquiz-frontend-neg"
  region                = var.region
  network_endpoint_type = "SERVERLESS"

  cloud_run {
    service = google_cloud_run_v2_service.frontend.name
  }

  depends_on = [google_project_service.compute]
}

resource "google_compute_region_network_endpoint_group" "auth" {
  name                  = "odsquiz-auth-neg"
  region                = var.region
  network_endpoint_type = "SERVERLESS"

  cloud_run {
    service = google_cloud_run_v2_service.auth.name
  }

  depends_on = [google_project_service.compute]
}

resource "google_compute_region_network_endpoint_group" "initiatives" {
  name                  = "odsquiz-initiatives-neg"
  region                = var.region
  network_endpoint_type = "SERVERLESS"

  cloud_run {
    service = google_cloud_run_v2_service.initiatives.name
  }

  depends_on = [google_project_service.compute]
}

resource "google_compute_backend_service" "frontend" {
  name                  = "odsquiz-frontend-backend"
  protocol              = "HTTP"
  load_balancing_scheme = "EXTERNAL_MANAGED"

  backend {
    group = google_compute_region_network_endpoint_group.frontend.id
  }
}

resource "google_compute_backend_service" "auth" {
  name                  = "odsquiz-auth-backend"
  protocol              = "HTTP"
  load_balancing_scheme = "EXTERNAL_MANAGED"

  backend {
    group = google_compute_region_network_endpoint_group.auth.id
  }
}

resource "google_compute_backend_service" "initiatives" {
  name                  = "odsquiz-initiatives-backend"
  protocol              = "HTTP"
  load_balancing_scheme = "EXTERNAL_MANAGED"

  backend {
    group = google_compute_region_network_endpoint_group.initiatives.id
  }
}

resource "google_compute_url_map" "odsquiz" {
  name            = "odsquiz-url-map"
  default_service = google_compute_backend_service.frontend.id

  host_rule {
    hosts        = ["*"]
    path_matcher = "odsquiz"
  }

  path_matcher {
    name            = "odsquiz"
    default_service = google_compute_backend_service.frontend.id

    path_rule {
      paths = [
        "/api/auth",
        "/api/auth/*",
      ]
      service = google_compute_backend_service.auth.id
    }

    path_rule {
      paths = [
        "/api/initiatives",
        "/api/initiatives/*",
      ]
      service = google_compute_backend_service.initiatives.id
    }
  }
}

resource "google_compute_target_http_proxy" "odsquiz" {
  name    = "odsquiz-http-proxy"
  url_map = google_compute_url_map.odsquiz.id
}

resource "google_compute_global_forwarding_rule" "odsquiz_http" {
  name                  = "odsquiz-http-forwarding-rule"
  ip_address            = google_compute_global_address.odsquiz_lb.address
  port_range            = "80"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  target                = google_compute_target_http_proxy.odsquiz.id
}
