output "bucket_data_url" {
  description = "URL del bucket de data cruda"
  value       = google_storage_bucket.data.url
}

output "bucket_config_url" {
  description = "URL del bucket de configuración"
  value       = google_storage_bucket.config.url
}