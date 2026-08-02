output "auth_service_url" {
  description = "Public URL for the auth Cloud Run service."
  value       = google_cloud_run_v2_service.auth.uri
}

output "initiatives_service_url" {
  description = "Public URL for the initiatives Cloud Run service."
  value       = google_cloud_run_v2_service.initiatives.uri
}

output "frontend_service_url" {
  description = "Public URL for the frontend Cloud Run service."
  value       = google_cloud_run_v2_service.frontend.uri
}

output "database_connection_name" {
  description = "Cloud SQL instance connection name."
  value       = google_sql_database_instance.main.connection_name
}

output "database_name" {
  description = "Database created inside Cloud SQL."
  value       = google_sql_database.app.name
}

output "database_user_secret" {
  description = "Secret Manager secret name used for the database username."
  value       = var.db_user
}

output "database_password_secret" {
  description = "Secret Manager secret name used for the database password."
  value       = var.db_password
}
