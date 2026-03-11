output "function_uri" {
  description = "URL para invocar la Cloud Function de Calidad"
  value       = google_cloudfunctions2_function.fn.service_config[0].uri
}