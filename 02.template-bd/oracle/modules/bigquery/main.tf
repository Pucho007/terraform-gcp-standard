resource "google_bigquery_dataset" "staging" {
  dataset_id = var.dataset_staging_name
  location   = var.region
}
resource "google_bigquery_dataset" "prod" {
  dataset_id = var.dataset_prod_name
  location   = var.region
}