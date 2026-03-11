# 1. Crea el repositorio vacío
resource "google_dataform_repository" "repo_vooxell" {
  provider = google-beta
  project = var.project_id
  region  = var.region
  name    = var.repository_name
}

# 2. Crea el SA de Dataform usando la variable del cliente
resource "google_service_account" "dataform_sa" {
  account_id   = var.dataform_sa_name  
  display_name = "Cuenta de Servicio para Dataform"
  project      = var.project_id
}

# 3. Le da poder de Admin en BigQuery al Robot
resource "google_project_iam_member" "dataform_bq_admin" {
  project = var.project_id
  role    = "roles/bigquery.admin"
  member  = "serviceAccount:${google_service_account.dataform_sa.email}"
}