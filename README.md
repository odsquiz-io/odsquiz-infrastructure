# ODS Quiz Infrastructure

Terraform configuration for the current ODS Quiz development environment on Google Cloud.

## What It Manages

- Required Google Cloud APIs:
  - Cloud Run
  - Cloud SQL Admin
  - Compute Engine
  - Cloud DNS
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
- Optional custom domain and HTTPS:
  - Google-managed SSL certificate
  - target HTTPS proxy
  - global forwarding rule on port `443`
  - HTTP-to-HTTPS redirect after `custom_domains` is configured

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

After configuring `custom_domains`, the public entry point is:

```text
https://<your-domain>
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

Custom domains:

```hcl
custom_domains = []
```

Set this to one or more DNS names. When using Cloudflare, set
`cloudflare_zone_id` too and Terraform creates the `A` records automatically.

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

## Custom Domain and HTTPS

1. Choose the domain name, for example:

```hcl
custom_domains = ["odsquiz.example.com"]
```

2. If using an external DNS provider, point DNS to the load balancer IP returned by Terraform:

```text
A odsquiz.example.com -> 136.68.80.85
```

With Cloudflare, set the zone ID in `terraform.tfvars` instead:

```hcl
custom_domains     = ["odsquiz.com"]
cloudflare_zone_id = "your-cloudflare-zone-id"
```

Before each Terraform operation, expose the Cloudflare API token only for the
current shell. The token is retrieved from Secret Manager and is not written to
Terraform configuration or state:

```bash
export CLOUDFLARE_API_TOKEN="$(gcloud secrets versions access latest --secret=CLOUDFLARE_TERRAFORM_TOKEN --project=odsquiz-dev)"
```

The Terraform-managed `A` records initially use Cloudflare's DNS-only mode so
that Google's managed certificate can validate the domain. Do not enable the
Cloudflare proxy until the certificate status is `ACTIVE`.

3. Apply Terraform:

```bash
terraform apply
```

4. Wait for the Google-managed certificate to become active. This can take several minutes after DNS resolves globally.

Check certificate status:

```bash
gcloud compute ssl-certificates describe odsquiz-managed-cert --global --project=odsquiz-dev
```

When the certificate is active, HTTP requests on port `80` redirect to HTTPS on port `443`.

Terraform state is stored in:

```text
gs://odsquiz-terraform/odsquiz-infrastructure
```

## On-Demand Billable Infrastructure

The **Manage Billable Development Infrastructure** GitHub Actions workflow can
start or stop the development Cloud Run services, Cloud SQL database stack, and
load balancer. It runs the shared `terraform-billable-infrastructure.yaml`
workflow from `odsquiz-workflows` with GitHub OIDC; no Google service-account
key or Cloudflare token is stored in GitHub.

Before running it, configure these repository variables in
`odsquiz-io/odsquiz-infrastructure`:

- `GCP_PROJECT_ID` — `odsquiz-dev`.
- `GCP_WORKLOAD_IDENTITY_PROVIDER` — the full Workload Identity Provider
  resource name trusted for this repository.
- `GCP_SERVICE_ACCOUNT` — the Google service account that GitHub Actions may
  impersonate.

The service account must be allowed to administer the selected Cloud Run, Cloud
SQL, and load-balancer resources, read/write the Terraform state bucket, and
read the latest version of `CLOUDFLARE_TERRAFORM_TOKEN` from Secret Manager.
It also needs the GitHub OIDC principal granted `roles/iam.workloadIdentityUser`
on that service account.

Use the **action** selector to choose **start** or **stop**. Stop permanently
deletes the Cloud SQL instance and its current data, the Cloud Run services,
and the load balancer including its reserved IP and managed certificate. The
next start creates a new IP, updates the existing Cloudflare record through
Terraform, and may need time for the managed certificate to become active
again.

Cloudflare DNS resources, Secret Manager secrets, project APIs, IAM bindings,
and Artifact Registry images are not included in either action.

## Common Commands

Create or update the Cloud Run services, Cloud SQL database stack, and load balancer:

```bash
terraform apply -target=google_cloud_run_v2_service.auth -target=google_cloud_run_v2_service.initiatives -target=google_cloud_run_v2_service.frontend -target=google_sql_user.app -target=google_sql_database.app -target=google_sql_database_instance.main -target=google_compute_global_address.odsquiz_lb -target=google_compute_region_network_endpoint_group.frontend -target=google_compute_region_network_endpoint_group.auth -target=google_compute_region_network_endpoint_group.initiatives -target=google_compute_backend_service.frontend -target=google_compute_backend_service.auth -target=google_compute_backend_service.initiatives -target=google_compute_url_map.odsquiz -target=google_compute_url_map.odsquiz_https_redirect -target=google_compute_managed_ssl_certificate.odsquiz -target=google_compute_target_http_proxy.odsquiz -target=google_compute_target_https_proxy.odsquiz -target=google_compute_global_forwarding_rule.odsquiz_http -target=google_compute_global_forwarding_rule.odsquiz_https -target=cloudflare_dns_record.custom_domain
```

Destroy the Cloud Run services, Cloud SQL database stack, and load balancer:

```bash
terraform destroy -target=google_cloud_run_v2_service.auth -target=google_cloud_run_v2_service.initiatives -target=google_cloud_run_v2_service.frontend -target=google_sql_user.app -target=google_sql_database.app -target=google_sql_database_instance.main -target=google_compute_global_address.odsquiz_lb -target=google_compute_region_network_endpoint_group.frontend -target=google_compute_region_network_endpoint_group.auth -target=google_compute_region_network_endpoint_group.initiatives -target=google_compute_backend_service.frontend -target=google_compute_backend_service.auth -target=google_compute_backend_service.initiatives -target=google_compute_url_map.odsquiz -target=google_compute_url_map.odsquiz_https_redirect -target=google_compute_managed_ssl_certificate.odsquiz -target=google_compute_target_http_proxy.odsquiz -target=google_compute_target_https_proxy.odsquiz -target=google_compute_global_forwarding_rule.odsquiz_http -target=google_compute_global_forwarding_rule.odsquiz_https
```

## Outputs

Terraform returns:

- `auth_service_url`
- `initiatives_service_url`
- `frontend_service_url`
- `load_balancer_ip`
- `load_balancer_http_url`
- `load_balancer_https_urls`
- `managed_ssl_certificate_name`
- `database_connection_name`
- `database_name`
- `database_user_secret`
- `database_password_secret`
