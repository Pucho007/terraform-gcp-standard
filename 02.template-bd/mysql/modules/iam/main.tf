resource "google_service_account" "sa" {
  account_id   = var.sa_name
  display_name = "Service Account para Ingesta"
  project      = var.project_id
}