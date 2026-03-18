output "dataset_staging_id" {
  description = "ID del dataset de staging"
  value       = google_bigquery_dataset.staging.dataset_id
}

output "dataset_prod_id" {
  description = "ID del dataset de producción"
  value       = google_bigquery_dataset.prod.dataset_id
}