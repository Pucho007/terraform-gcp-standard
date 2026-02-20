resource "google_storage_bucket" "app_storage" {
  name                     = var.bucket_name
  project                  = var.project_id
  location                 = var.region
  storage_class            = "STANDARD"
  force_destroy            = false
  public_access_prevention = "enforced"
  labels                   = var.common_labels

  versioning {
    enabled = true
  }
}