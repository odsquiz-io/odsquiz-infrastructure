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
  }
}

provider "google" {
  project = var.project
  region  = var.region
}
