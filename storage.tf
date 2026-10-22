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
