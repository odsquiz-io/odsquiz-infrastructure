# ODS Quiz Infrastructure

Terraform configuration for the current ODS Quiz development environment on Google Cloud.

## What It Manages

- Required Google Cloud APIs:
  - Cloud Run
  - Cloud SQL Admin
  - Compute Engine
  - Secret Manager
- Secret Manager secret containers:
  - `DB_USER`
  - `DB_PASSWORD`
  - `JWT_SECRET`
- IAM bindings for the Cloud Run service account:
  - Cloud SQL Client
  - Secret Manager Secret Accessor
- Cloud SQL PostgreSQL instance:
  - PostgreSQL 16
  - `db-f1-micro`
  - zonal
  - 10 GB SSD
  - backups disabled
- Application database and database user.
- Three Cloud Run services:
  - `odsquiz-auth`
  - `odsquiz-initiatives`
  - `odsquiz-frontend`
- External HTTP Application Load Balancer:
  - global static IP
  - serverless NEGs
  - backend services
  - URL map
  - target HTTP proxy
  - global forwarding rule on port `80`

## File Structure

- `versions.tf`: Terraform version, providers, GCS backend, and Google provider config.
- `services.tf`: Google Cloud APIs, Secret Manager secrets, and project IAM bindings.
- `database.tf`: Cloud SQL instance, application database, and database user.
- `apis.tf`: Cloud Run services for auth, initiatives, and frontend.
- `load-balancer.tf`: External HTTP Application Load Balancer and path routing.
- `variables.tf`: Input variables and defaults.
- `outputs.tf`: Service URLs, load balancer URL/IP, database connection name, and secret names.
- `terraform.tfvars.example`: Example values for the dev environment.
- `imports.tf`: Terraform import blocks for existing APIs and secrets.
- `main.tf`: currently empty.
- `openapi.yaml`: legacy API Gateway config, not used by the current Load Balancer direction.

## Current Cloud Run Shape

`odsquiz-auth`:

- Image: `var.auth_image`
- Port: `8080`
- Uses Cloud SQL Unix socket volume.
- Reads `JWTSecret`, `DB_USER`, and `DB_PASSWORD` from Secret Manager.
- Receives database settings through environment variables.
- Ingress is restricted to internal traffic and external Application Load Balancers.

`odsquiz-initiatives`:

- Image: `var.initiatives_image`
- Port: `8080`
- Uses Cloud SQL Unix socket volume.
- Reads `JWTSecret`, `DB_USER`, and `DB_PASSWORD` from Secret Manager.
- Receives database settings through environment variables.
- Ingress is restricted to internal traffic and external Application Load Balancers.

`odsquiz-frontend`:

- Image: `var.frontend_image`
- Port: `3000`
- Receives `AUTH_API_URL` and `INITIATIVES_API_URL` for server-side rewrites.
- Ingress is restricted to internal traffic and external Application Load Balancers.

## Load Balancer Routing

Current public entry point:

```text
http://136.68.80.85
```

Path routing:

```text
/api/auth         -> odsquiz-auth
/api/auth/*       -> odsquiz-auth
/api/initiatives  -> odsquiz-initiatives
/api/initiatives/* -> odsquiz-initiatives
/*                -> odsquiz-frontend
```

## Current Defaults

Project:

```hcl
project = "odsquiz-dev"
region  = "us-central1"
```

Images:

```hcl
auth_image        = "us-central1-docker.pkg.dev/odsquiz-dev/odsquiz/odsquiz-auth:latest"
initiatives_image = "us-central1-docker.pkg.dev/odsquiz-dev/odsquiz/odsquiz-initiatives:latest"
frontend_image    = "us-central1-docker.pkg.dev/odsquiz-dev/odsquiz/odsquiz-frontend:latest"
```

Database:

```hcl
sql_instance_name = "odsquiz-dev-db"
db_name           = "odsquiz"
db_user           = "DB_USER"
db_password       = "DB_PASSWORD"
jwt_secret        = "JWT_SECRET"
```

## Usage

Initialize Terraform:

```bash
terraform init
```

Preview changes:

```bash
terraform plan
```

Apply changes:

```bash
terraform apply
```

Terraform state is stored in:

```text
gs://odsquiz-terraform/odsquiz-infrastructure
```

## Common Commands

Create or update the Cloud Run services, Cloud SQL database stack, and load balancer:

```bash
terraform apply -target=google_cloud_run_v2_service.auth -target=google_cloud_run_v2_service.initiatives -target=google_cloud_run_v2_service.frontend -target=google_sql_user.app -target=google_sql_database.app -target=google_sql_database_instance.main -target=google_compute_global_address.odsquiz_lb -target=google_compute_region_network_endpoint_group.frontend -target=google_compute_region_network_endpoint_group.auth -target=google_compute_region_network_endpoint_group.initiatives -target=google_compute_backend_service.frontend -target=google_compute_backend_service.auth -target=google_compute_backend_service.initiatives -target=google_compute_url_map.odsquiz -target=google_compute_target_http_proxy.odsquiz -target=google_compute_global_forwarding_rule.odsquiz_http
```

Destroy the Cloud Run services, Cloud SQL database stack, and load balancer:

```bash
terraform destroy -target=google_cloud_run_v2_service.auth -target=google_cloud_run_v2_service.initiatives -target=google_cloud_run_v2_service.frontend -target=google_sql_user.app -target=google_sql_database.app -target=google_sql_database_instance.main -target=google_compute_global_address.odsquiz_lb -target=google_compute_region_network_endpoint_group.frontend -target=google_compute_region_network_endpoint_group.auth -target=google_compute_region_network_endpoint_group.initiatives -target=google_compute_backend_service.frontend -target=google_compute_backend_service.auth -target=google_compute_backend_service.initiatives -target=google_compute_url_map.odsquiz -target=google_compute_target_http_proxy.odsquiz -target=google_compute_global_forwarding_rule.odsquiz_http
```

## Outputs

Terraform returns:

- `auth_service_url`
- `initiatives_service_url`
- `frontend_service_url`
- `load_balancer_ip`
- `load_balancer_http_url`
- `database_connection_name`
- `database_name`
- `database_user_secret`
- `database_password_secret`

## Next Infrastructure Step

The next planned infrastructure change is adding a custom domain and HTTPS with a managed certificate.
