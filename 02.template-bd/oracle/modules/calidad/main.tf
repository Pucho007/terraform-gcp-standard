# 1. Terraform comprime la carpeta automáticamente
data "archive_file" "codigo_zip" {
  type        = "zip"
  source_dir  = "../src/calidad/funcion" # Tu carpeta con los scripts sueltos
  output_path = "../src/calidad/funcion_generada.zip" # El archivo que creará Terraform
}

# 2. Sube el zip recién creado al bucket (¡AQUÍ ESTÁ EL CAMBIO!)
resource "google_storage_bucket_object" "zip" {
  # Inyectamos el output_md5 para que el nombre cambie si el código cambia
  name   = "codigo_funcion_${data.archive_file.codigo_zip.output_md5}.zip"
  bucket = var.bucket_config_name
  source = data.archive_file.codigo_zip.output_path # Apunta al zip generado
}

# 3. Creamos la Cloud Function v2
resource "google_cloudfunctions2_function" "fn" {
  name     = var.function_calidad_name
  location = var.region
  
  build_config {
    runtime     = "python310"
    entry_point = "main"
    source {
      storage_source {
        bucket = var.bucket_config_name
        # Como aquí usas .name, Terraform tomará automáticamente el nuevo nombre con el hash
        object = google_storage_bucket_object.zip.name
      }
    }
  }
  
  service_config {
    service_account_email = var.sa_email
    
    # AQUÍ LE PASAMOS EL NOMBRE DEL BUCKET AL PYTHON:
    environment_variables = {
      BUCKET_CONFIG = var.bucket_config_name
    }
  }
}