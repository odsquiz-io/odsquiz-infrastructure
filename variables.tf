variable "project" {
  description = "GCP project ID where the resources will be created."
  type        = string
  default     = "odsquiz-dev"
}

variable "region" {
  description = "Default region for Cloud Run and Cloud SQL resources."
  type        = string
  default     = "us-central1"
}

variable "auth_service_name" {
  description = "Cloud Run service name for the auth API."
  type        = string
  default     = "odsquiz-auth"
}

variable "initiatives_service_name" {
  description = "Cloud Run service name for the initiatives API."
  type        = string
  default     = "odsquiz-initiatives"
}

variable "frontend_service_name" {
  description = "Cloud Run service name for the frontend app."
  type        = string
  default     = "odsquiz-frontend"
}

variable "auth_image" {
  description = "Container image for the auth service."
  type        = string
  default     = "us-central1-docker.pkg.dev/odsquiz-dev/odsquiz/odsquiz-auth:latest"
}

variable "initiatives_image" {
  description = "Container image for the initiatives service."
  type        = string
  default     = "us-central1-docker.pkg.dev/odsquiz-dev/odsquiz/odsquiz-initiatives:latest"
}

variable "frontend_image" {
  description = "Container image for the frontend service."
  type        = string
  default     = "us-central1-docker.pkg.dev/odsquiz-dev/odsquiz/odsquiz-frontend:latest"
}

variable "cloud_run_service_account" {
  description = "Service account used by the Cloud Run services."
  type        = string
  default     = "applications-sa@odsquiz-dev.iam.gserviceaccount.com"
}

variable "sql_instance_name" {
  description = "Cloud SQL instance name."
  type        = string
  default     = "odsquiz-dev-db"
}

variable "db_name" {
  description = "Default database name inside the Cloud SQL instance."
  type        = string
  default     = "odsquiz"
}

variable "db_user" {
  description = "Name of the Secret Manager secret that stores the database username."
  type        = string
  default     = "DB_USER"
}

variable "db_password" {
  description = "Name of the Secret Manager secret that stores the database password."
  type        = string
  default     = "DB_PASSWORD"
}

variable "jwt_secret" {
  description = "Name of the Secret Manager secret that stores the JWT signing secret."
  type        = string
  default     = "JWT_SECRET"
}

variable "auth_api_url" {
  description = "Public URL of the auth Cloud Run service used by the frontend."
  type        = string
  default     = ""
}

variable "initiatives_api_url" {
  description = "Public URL of the initiatives Cloud Run service used by the frontend."
  type        = string
  default     = ""
}

variable "custom_domains" {
  description = "Domain names served by the external Application Load Balancer HTTPS certificate."
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for domain in var.custom_domains : length(trimspace(domain)) > 0])
    error_message = "custom_domains must contain only non-empty domain names."
  }
}

variable "cloudflare_zone_id" {
  description = "Cloudflare zone ID that contains custom_domains. Leave null to manage DNS outside Terraform."
  type        = string
  default     = "f9beaa8c263a4c96fea2ce76de1093f2"
  nullable    = true
}
