# ODS Quiz Infrastructure

Terraform configuration for the current ODS Quiz development environment on Google Cloud.

## What It Manages

- Required Google Cloud APIs:
  - Cloud Run
  - Cloud SQL Admin
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

## File Structure

- `versions.tf`: Terraform version, providers, GCS backend, and Google provider config.
- `services.tf`: Google Cloud APIs, Secret Manager secrets, and project IAM bindings.
- `database.tf`: Cloud SQL instance, application database, and database user.
- `apis.tf`: Cloud Run services for auth, initiatives, and frontend.
- `variables.tf`: Input variables and defaults.
- `outputs.tf`: Service URLs, database connection name, and secret names.
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

`odsquiz-initiatives`:

- Image: `var.initiatives_image`
- Port: `8080`
- Uses Cloud SQL Unix socket volume.
- Reads `JWTSecret`, `DB_USER`, and `DB_PASSWORD` from Secret Manager.
- Receives database settings through environment variables.

`odsquiz-frontend`:

- Image: `var.frontend_image`
- Port: `3000`
- Currently receives backend service URLs through environment variables.
- The application code is being moved toward same-origin `/api/...` calls for a future Load Balancer.

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

## Outputs

Terraform returns:

- `auth_service_url`
- `initiatives_service_url`
- `frontend_service_url`
- `database_connection_name`
- `database_name`
- `database_user_secret`
- `database_password_secret`

## Next Infrastructure Step

The next planned infrastructure change is an external Application Load Balancer with path-based routing:

```text
/api/auth/*        -> odsquiz-auth
/api/initiatives*  -> odsquiz-initiatives
/*                 -> odsquiz-frontend
```

After the Load Balancer is working, Cloud Run ingress should be restricted so backend services are not accessed directly.
