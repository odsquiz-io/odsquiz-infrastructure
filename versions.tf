terraform {
  required_version = ">= 1.5.0"

  backend "gcs" {
    bucket = "odsquiz-terraform"
    prefix = "odsquiz-infrastructure"
  }

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.7"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project
  region  = var.region
}

# Configure credentials with CLOUDFLARE_API_TOKEN at runtime. Do not store the
# token in Terraform files or state.
provider "cloudflare" {}
