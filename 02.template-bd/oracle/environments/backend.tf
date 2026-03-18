terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "7.20.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "7.20.0"
    }
  }
  backend "gcs" {
    prefix = "terraform/state/env"
  }
}
