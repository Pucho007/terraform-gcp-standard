resource "google_bigquery_dataset" "analytics" {
  dataset_id                  = var.dataset_name
  project                     = var.project_id
  location                    = var.region
  
  # Buena práctica: añadir una descripción
  friendly_name               = "Dataset Analitica Corporativa"
  description                 = "Dataset administrado centralmente por Terraform"
  
  # Opcional pero recomendado para FinOps: borrar particiones viejas (ej: 90 días)
  # default_partition_expiration_ms = 7776000000 

  labels = var.common_labels
}