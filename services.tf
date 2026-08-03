resource "google_project_service" "run" {
  service            = "run.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "sqladmin" {
  service            = "sqladmin.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "secretmanager" {
  service            = "secretmanager.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "compute" {
  service            = "compute.googleapis.com"
  disable_on_destroy = false
}

resource "google_secret_manager_secret" "db_user" {
  secret_id           = var.db_user
  deletion_protection = false

  replication {
    auto {}
  }

  depends_on = [google_project_service.secretmanager]
}

resource "google_secret_manager_secret" "db_password" {
  secret_id           = var.db_password
  deletion_protection = false

  replication {
    auto {}
  }

  depends_on = [google_project_service.secretmanager]
}

resource "google_secret_manager_secret" "jwt_secret" {
  secret_id           = var.jwt_secret
  deletion_protection = false

  replication {
    auto {}
  }

  depends_on = [google_project_service.secretmanager]
}

data "google_secret_manager_secret_version" "db_user" {
  secret = var.db_user

  depends_on = [google_project_service.secretmanager]
}

data "google_secret_manager_secret_version" "db_password" {
  secret = var.db_password

  depends_on = [google_project_service.secretmanager]
}

resource "google_project_iam_member" "cloud_run_sql_client" {
  project = var.project
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${var.cloud_run_service_account}"
}

resource "google_project_iam_member" "cloud_run_secret_accessor" {
  project = var.project
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${var.cloud_run_service_account}"
}
