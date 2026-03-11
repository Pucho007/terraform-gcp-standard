# 1. Bucket para la Data Cruda (CSV)
resource "google_storage_bucket" "data" {
  name          = var.bucket_data_name
  location      = var.region
  force_destroy = true
  uniform_bucket_level_access = true
}

# 2. Bucket para la Configuración (Reglas de Calidad)
resource "google_storage_bucket" "config" {
  name          = var.bucket_config_name
  location      = var.region
  force_destroy = true
  uniform_bucket_level_access = true
}

# 3. Subimos el archivo de reglas al bucket de configuración
resource "google_storage_bucket_object" "reglas" {
  name   = "reglas_calidad.json"
  bucket = google_storage_bucket.config.name
  source = "../src/calidad/reglas_calidad.json"
}