resource "google_bigquery_dataset" "analytics" {
  dataset_id                  = var.dataset_name
  project                     = var.project_id
  location                    = var.region
  
  # Buena práctica: añadir una descripción
  friendly_name               = "Dataset Analitica Corporativa"
  description                 = "Dataset administrado centralmente por Terraform"

  labels = var.common_labels
}

#  Crea el dataset de destino para Dataform
resource "google_bigquery_dataset" "dataset_destino" {
  dataset_id                 = var.dataset_destino_name
  location                   = var.region
  project                    = var.project_id
  delete_contents_on_destroy = true #  permite a Terraform borrarlo si destruyes la infra
}