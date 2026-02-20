# terraform {
#   required_version = ">= 1.5.0"
#   required_providers {
#     google = {
#       source  = "hashicorp/google"
#       version = "~> 5.0"
#     }
#   }

#   # backend "gcs" {
#   #   bucket = "tf-state-mi-proyecto-123" # Descomentar después del primer apply
#   #   prefix = "terraform/state/dev"
#   # }
# }

terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "7.20.0"
    }
  }
}
