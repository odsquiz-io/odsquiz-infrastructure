resource "google_cloud_run_v2_service" "auth" {
  name                 = var.auth_service_name
  location             = var.region
  ingress              = "INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER"
  invoker_iam_disabled = true
  deletion_protection  = false

  template {
    service_account = var.cloud_run_service_account

    volumes {
      name = "cloudsql"
      cloud_sql_instance {
        instances = [google_sql_database_instance.main.connection_name]
      }
    }

    containers {
      image = var.auth_image
      ports {
        container_port = 8080
      }
      volume_mounts {
        name       = "cloudsql"
        mount_path = "/cloudsql"
      }
      env {
        name = "JWTSecret"
        value_source {
          secret_key_ref {
            secret  = var.jwt_secret
            version = "latest"
          }
        }
      }
      env {
        name  = "DB_HOST"
        value = "/cloudsql/${google_sql_database_instance.main.connection_name}"
      }
      env {
        name  = "DB_PORT"
        value = "5432"
      }
      env {
        name = "DB_USER"
        value_source {
          secret_key_ref {
            secret  = var.db_user
            version = "latest"
          }
        }
      }
      env {
        name = "DB_PASSWORD"
        value_source {
          secret_key_ref {
            secret  = var.db_password
            version = "latest"
          }
        }
      }
      env {
        name  = "DB_NAME"
        value = var.db_name
      }
      env {
        name  = "DB_SSLMODE"
        value = "disable"
      }
      resources {
        limits = {
          cpu    = "1000m"
          memory = "512Mi"
        }
      }
    }

    scaling {
      min_instance_count = 0
      max_instance_count = 1
    }
  }

  depends_on = [
    google_project_iam_member.cloud_run_secret_accessor,
    google_project_iam_member.cloud_run_sql_client,
    google_project_service.run,
    # The service runs migrations during startup, so its database and login
    # must exist before Cloud Run creates its first revision.
    google_sql_database.app,
    google_sql_user.app,
  ]

  lifecycle {
    ignore_changes = [scaling]
  }
}

resource "google_cloud_run_v2_service" "initiatives" {
  name                 = var.initiatives_service_name
  location             = var.region
  ingress              = "INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER"
  invoker_iam_disabled = true
  deletion_protection  = false

  template {
    service_account = var.cloud_run_service_account

    volumes {
      name = "cloudsql"
      cloud_sql_instance {
        instances = [google_sql_database_instance.main.connection_name]
      }
    }

    containers {
      image = var.initiatives_image
      ports {
        container_port = 8080
      }
      volume_mounts {
        name       = "cloudsql"
        mount_path = "/cloudsql"
      }
      env {
        name = "JWTSecret"
        value_source {
          secret_key_ref {
            secret  = var.jwt_secret
            version = "latest"
          }
        }
      }
      env {
        name  = "DB_HOST"
        value = "/cloudsql/${google_sql_database_instance.main.connection_name}"
      }
      env {
        name  = "DB_PORT"
        value = "5432"
      }
      env {
        name = "DB_USER"
        value_source {
          secret_key_ref {
            secret  = var.db_user
            version = "latest"
          }
        }
      }
      env {
        name = "DB_PASSWORD"
        value_source {
          secret_key_ref {
            secret  = var.db_password
            version = "latest"
          }
        }
      }
      env {
        name  = "DB_NAME"
        value = var.db_name
      }
      env {
        name  = "DB_SSLMODE"
        value = "disable"
      }
      resources {
        limits = {
          cpu    = "1000m"
          memory = "512Mi"
        }
      }
    }

    scaling {
      min_instance_count = 0
      max_instance_count = 1
    }
  }

  depends_on = [
    google_project_iam_member.cloud_run_secret_accessor,
    google_project_iam_member.cloud_run_sql_client,
    google_project_service.run,
    # The service runs migrations during startup, so its database and login
    # must exist before Cloud Run creates its first revision.
    google_sql_database.app,
    google_sql_user.app,
  ]

  lifecycle {
    ignore_changes = [scaling]
  }
}

resource "google_cloud_run_v2_service" "frontend" {
  name                 = var.frontend_service_name
  location             = var.region
  ingress              = "INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER"
  invoker_iam_disabled = true
  deletion_protection  = false

  template {
    service_account = var.cloud_run_service_account

    containers {
      image = var.frontend_image
      ports {
        container_port = 3000
      }
      env {
        name  = "AUTH_API_URL"
        value = var.auth_api_url != "" ? var.auth_api_url : google_cloud_run_v2_service.auth.uri
      }
      env {
        name  = "INITIATIVES_API_URL"
        value = var.initiatives_api_url != "" ? var.initiatives_api_url : google_cloud_run_v2_service.initiatives.uri
      }
      resources {
        limits = {
          cpu    = "1000m"
          memory = "512Mi"
        }
      }
    }

    scaling {
      min_instance_count = 0
      max_instance_count = 1
    }
  }

  depends_on = [
    google_cloud_run_v2_service.auth,
    google_cloud_run_v2_service.initiatives,
  ]

  lifecycle {
    ignore_changes = [scaling]
  }
}
