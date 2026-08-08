project = "odsquiz-dev"
region  = "us-central1"

auth_service_name        = "odsquiz-auth"
initiatives_service_name = "odsquiz-initiatives"
frontend_service_name    = "odsquiz-frontend"

auth_image        = "us-central1-docker.pkg.dev/odsquiz-dev/odsquiz/odsquiz-auth:latest"
initiatives_image = "us-central1-docker.pkg.dev/odsquiz-dev/odsquiz/odsquiz-initiatives:latest"
frontend_image    = "us-central1-docker.pkg.dev/odsquiz-dev/odsquiz/odsquiz-frontend:latest"

cloud_run_service_account = "applications-sa@odsquiz-dev.iam.gserviceaccount.com"

sql_instance_name = "odsquiz-dev-db"
db_name           = "odsquiz"
db_user           = "DB_USER"
db_password       = "DB_PASSWORD"

custom_domains = ["odsquiz.com"]