output "auth_service_url" {
  description = "Public URL for the auth Cloud Run service."
  value       = google_cloud_run_v2_service.auth.uri
}

output "initiatives_service_url" {
  description = "Public URL for the initiatives Cloud Run service."
  value       = google_cloud_run_v2_service.initiatives.uri
}

output "quiz_service_url" {
  description = "Public URL for the quiz Cloud Run service."
  value       = google_cloud_run_v2_service.quiz.uri
}

output "admin_service_url" {
  description = "Public URL for the admin Cloud Run service."
  value       = google_cloud_run_v2_service.admin.uri
}

output "frontend_service_url" {
  description = "Public URL for the frontend Cloud Run service."
  value       = google_cloud_run_v2_service.frontend.uri
}

output "public_urls" {
  description = "Public HTTPS URLs served through the Cloudflare router Worker."
  value       = [for domain in var.custom_domains : "https://${domain}"]
}

output "database_instance_name" {
  description = "Cloud SQL instance name, available even while the billable resources are stopped."
  value       = var.sql_instance_name
}

output "database_connection_name" {
  description = "Cloud SQL instance connection name."
  value       = google_sql_database_instance.main.connection_name
}

output "database_name" {
  description = "Database created inside Cloud SQL."
  value       = var.db_name
}

output "database_user_secret" {
  description = "Secret Manager secret name used for the database username."
  value       = var.db_user
}

output "database_password_secret" {
  description = "Secret Manager secret name used for the database password."
  value       = var.db_password
}

output "media_bucket_name" {
  description = "Cloud Storage bucket that stores initiative logos and photos."
  value       = google_storage_bucket.media.name
}

output "db_exports_bucket_name" {
  description = "Cloud Storage bucket that keeps the SQL export taken when the billable resources stop."
  value       = google_storage_bucket.db_exports.name
}
