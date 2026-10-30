# ODS Quiz Infrastructure

Terraform configuration for the current ODS Quiz development environment on Google Cloud.

## What It Manages

- Required Google Cloud APIs:
  - Cloud Run
  - Cloud SQL Admin
  - Compute Engine
  - Cloud DNS
  - Secret Manager
  - Cloud Storage
- Secret Manager secret containers:
  - `DB_USER`
  - `DB_PASSWORD`
  - `JWT_SECRET`
- IAM bindings for the Cloud Run service account:
  - Cloud SQL Client
  - Secret Manager Secret Accessor
  - Storage Object Admin on the media bucket only
- Cloud Storage media bucket `<project>-media` (`odsquiz-dev-media`) for
  initiative logos and photos:
  - regional, in `var.region`
  - uniform bucket-level access
  - public access prevention enforced
  - `force_destroy = false`, no lifecycle rules
- Cloud Storage bucket `<project>-db-exports` (`odsquiz-dev-db-exports`) for
  the SQL export taken when the billable resources stop:
  - same access settings as the media bucket
  - object versioning, keeping the five most recent previous exports
  - Storage Object Admin for the Cloud SQL instance service account only
- Cloud SQL PostgreSQL instance:
  - PostgreSQL 16
  - `db-f1-micro`
  - zonal
  - 10 GB HDD
  - backups disabled
- Application database and database user.
- Five Cloud Run services:
  - `odsquiz-auth`
  - `odsquiz-initiatives`
  - `odsquiz-quiz`
  - `odsquiz-admin`
  - `odsquiz-frontend`
- Cloudflare routing for `custom_domains`:
  - `odsquiz-router` Worker that forwards each path to its Cloud Run service
  - proxied `AAAA 100::` placeholder record and a Workers route per domain
  - HTTP-to-HTTPS redirect done by the Worker
  - a maintenance page (HTML) or `503` JSON while the services are stopped

## File Structure

- `versions.tf`: Terraform version, providers, GCS backend, and Google provider config.
- `services.tf`: Google Cloud APIs, Secret Manager secrets, and project IAM bindings.
- `database.tf`: Cloud SQL instance, application database, and database user.
- `storage.tf`: Media and database export buckets and their bucket-level IAM bindings.
- `apis.tf`: Cloud Run services for auth, initiatives, quiz, admin, and frontend.
- `cloudflare.tf`: Cloudflare router Worker, its DNS record and Workers routes.
- `worker/router.js`: Worker source with the path routing table.
- `variables.tf`: Input variables and defaults.
- `outputs.tf`: Service URLs, public URLs, database names, secret names, and bucket names.
- `terraform.tfvars.example`: Example values for the dev environment.
- `imports.tf`: Terraform import blocks for existing APIs and secrets.
- `main.tf`: currently empty.

## Current Cloud Run Shape

All services accept traffic from any source (`INGRESS_TRAFFIC_ALL`) with IAM
invocation disabled; the public entry point is the Cloudflare Worker. They use
request-based billing (`cpu_idle = true`), scale to zero, and allow at most one
instance.

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
- Receives `STORAGE_BUCKET` with the media bucket name. Logos and photos are
  read and written through the API with the service account; the bucket itself
  is never public.

`odsquiz-quiz` and `odsquiz-admin`:

- Images: `var.quiz_image` and `var.admin_image`
- Same shape as the initiatives service: port `8080`, Cloud SQL Unix socket
  volume, and `JWTSecret`, `DB_USER`, and `DB_PASSWORD` from Secret Manager.

`odsquiz-frontend`:

- Image: `var.frontend_image`
- Port: `3000`
- Receives `AUTH_API_URL`, `INITIATIVES_API_URL`, `QUIZ_API_URL`, and
  `ADMIN_API_URL` for server-side rewrites, which are only used outside the
  Worker.

## Routing

Public entry point:

```text
https://odsquiz.com
```

The Worker forwards requests to the deterministic Cloud Run URLs
(`https://<service>-<project-number>.<region>.run.app`), which stay the same
when the services are destroyed and recreated:

```text
/api/auth         -> odsquiz-auth
/api/auth/*       -> odsquiz-auth
/api/initiatives  -> odsquiz-initiatives
/api/initiatives/* -> odsquiz-initiatives
/api/quiz         -> odsquiz-quiz
/api/quiz/*       -> odsquiz-quiz
/api/admin        -> odsquiz-admin
/api/admin/*      -> odsquiz-admin
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
quiz_image        = "us-central1-docker.pkg.dev/odsquiz-dev/odsquiz/odsquiz-quiz:latest"
admin_image       = "us-central1-docker.pkg.dev/odsquiz-dev/odsquiz/odsquiz-admin:latest"
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

Custom domains and Cloudflare:

```hcl
custom_domains        = ["odsquiz.com"]
cloudflare_zone_id    = "<zone id>"
cloudflare_account_id = "<account id>"
```

Set either Cloudflare ID to `null` to manage routing outside Terraform.

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

## Cloudflare Credentials

Before each Terraform operation, expose the Cloudflare API token only for the
current shell. The token is retrieved from Secret Manager and is not written to
Terraform configuration or state:

```bash
export CLOUDFLARE_API_TOKEN="$(gcloud secrets versions access latest --secret=CLOUDFLARE_TERRAFORM_TOKEN --project=odsquiz-dev)"
```

The token needs these permissions:

- Zone · DNS · Edit
- Zone · Workers Routes · Edit
- Account · Workers Scripts · Edit

Cloudflare terminates HTTPS with its Universal SSL certificate; no Google
certificate is involved.

Terraform state is stored in:

```text
gs://odsquiz-terraform/odsquiz-infrastructure
```

## On-Demand Billable Infrastructure

The **Manage Billable Development Infrastructure** GitHub Actions workflow can
start or stop the Cloud Run services and the Cloud SQL database stack. It runs
the shared `terraform-billable-infrastructure.yaml` workflow from
`odsquiz-workflows` with GitHub OIDC; no Google service-account key or
Cloudflare token is stored in GitHub.

Before running it, configure these repository variables in
`odsquiz-io/odsquiz-infrastructure`:

- `GCP_PROJECT_ID` — `odsquiz-dev`.
- `GCP_WORKLOAD_IDENTITY_PROVIDER` — the full Workload Identity Provider
  resource name trusted for this repository.
- `GCP_SERVICE_ACCOUNT` — the Google service account that GitHub Actions may
  impersonate.

The service account must be allowed to administer the Cloud Run and Cloud SQL
resources (including SQL import and export), read/write the Terraform state
bucket, and
read the latest versions of `CLOUDFLARE_TERRAFORM_TOKEN`, `DB_USER`, and
`DB_PASSWORD` from Secret Manager. It also needs the GitHub OIDC principal
granted `roles/iam.workloadIdentityUser` on that service account.

Terraform grants that service account (`var.workflow_service_account`) the
bucket access the workflow needs: Legacy Bucket Reader on the media bucket, so
targeted runs can refresh it, and Legacy Bucket Owner plus Storage Object Viewer
on the database export bucket, so it can manage the Cloud SQL grant there and
check whether an export exists.

Use the **action** selector to choose **start** or **stop**:

- **stop** exports the database to
  `gs://<project>-db-exports/<database>.sql.gz`, then deletes the Cloud Run
  services, the Cloud SQL instance, and the bucket grant of its service
  account. If the export fails, nothing is deleted.
- **start** creates the Cloud SQL stack, imports the latest export when one
  exists, and then creates the Cloud Run services, so their startup migrations
  run against the restored data.

While stopped, the Worker answers with a maintenance page. The Worker,
Cloudflare records, Secret Manager secrets, project APIs, IAM bindings, both
buckets, and Artifact Registry images are not included in either action. Create
them with a full `terraform apply` before relying on the workflow.

## Common Commands

Create the database stack, then the services (import the latest export in
between when needed):

```bash
terraform apply -target=google_sql_database_instance.main -target=google_sql_database.app -target=google_sql_user.app -target=google_storage_bucket_iam_member.sql_db_exports_object_admin
terraform apply -target=google_cloud_run_v2_service.auth -target=google_cloud_run_v2_service.initiatives -target=google_cloud_run_v2_service.quiz -target=google_cloud_run_v2_service.admin -target=google_cloud_run_v2_service.frontend
```

Destroy the services and the database stack (export first to keep the data):

```bash
terraform destroy -target=google_cloud_run_v2_service.auth -target=google_cloud_run_v2_service.initiatives -target=google_cloud_run_v2_service.quiz -target=google_cloud_run_v2_service.admin -target=google_cloud_run_v2_service.frontend -target=google_storage_bucket_iam_member.sql_db_exports_object_admin -target=google_sql_user.app -target=google_sql_database.app -target=google_sql_database_instance.main
```

## Outputs

Terraform returns:

- `auth_service_url`
- `initiatives_service_url`
- `quiz_service_url`
- `admin_service_url`
- `frontend_service_url`
- `public_urls`
- `database_instance_name`
- `database_connection_name`
- `database_name`
- `database_user_secret`
- `database_password_secret`
- `media_bucket_name`
- `db_exports_bucket_name`
