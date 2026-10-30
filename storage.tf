resource "google_storage_bucket" "media" {
  name                        = "${var.project}-media"
  location                    = var.region
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
  force_destroy               = false

  depends_on = [google_project_service.storage]
}

resource "google_storage_bucket_iam_member" "cloud_run_media_object_admin" {
  bucket = google_storage_bucket.media.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${var.cloud_run_service_account}"
}

# Holds the SQL export taken before the billable stop destroys Cloud SQL, so the
# next start can import it. Older exports are kept as noncurrent versions.
resource "google_storage_bucket" "db_exports" {
  name                        = "${var.project}-db-exports"
  location                    = var.region
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
  force_destroy               = false

  versioning {
    enabled = true
  }

  lifecycle_rule {
    condition {
      num_newer_versions = 5
      with_state         = "ARCHIVED"
    }
    action {
      type = "Delete"
    }
  }

  depends_on = [google_project_service.storage]
}

resource "google_storage_bucket_iam_member" "sql_db_exports_object_admin" {
  bucket = google_storage_bucket.db_exports.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_sql_database_instance.main.service_account_email_address}"
}
