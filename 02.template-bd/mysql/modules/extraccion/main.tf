# 1. Creamos el repositorio para guardar tu código empaquetado
resource "google_artifact_registry_repository" "repo" {
  location      = var.region
  repository_id = var.repo_docker_name
  format        = "DOCKER"
}

# 2 Construimos la "Caja" y la subimos
# Esto lee tu carpeta src/extraccion, usa el Dockerfile y lo sube al estante
resource "null_resource" "build_y_subir_docker" {
  
  # Este trigger vigila tus archivos. Si modificas el main.py, Terraform sabrá
  # que tiene que volver a construir y subir la imagen.
  triggers = {
    codigo_cambiado = sha1(join("", [for f in fileset("../src/extraccion", "**"): filesha1("../src/extraccion/${f}")]))
    espera          = var.espera_id
  }

  provisioner "local-exec" {
    # Usamos Cloud Build de Google para que construya el Docker en la nube, 
    # así no tienes que instalar Docker en tu PC.
    command = <<-EOT
      gcloud builds submit ../src/extraccion \
        --tag ${var.region}-docker.pkg.dev/${var.project_id}/${var.repo_docker_name}/extractor:latest \
        --project ${var.project_id}
    EOT
  }

  # Le decimos que espere a que el repositorio exista antes de intentar subir
  depends_on = [google_artifact_registry_repository.repo] 
}


# 3. Creamos el Cloud Run Job que va a USAR esa caja
resource "google_cloud_run_v2_job" "job" {
  name     = var.job_extraccion_name
  location = var.region
  template {
    template {
      service_account = var.sa_email
      containers {
        
        # AQUÍ SE ENLAZA CON LA IMAGEN QUE ACABAMOS DE SUBIR EN EL PASO 2
        image = "${var.region}-docker.pkg.dev/${var.project_id}/${var.repo_docker_name}/extractor:latest"
        
        # Inyectamos las variables
        env { 
          name  = "DB_HOST"
          value = var.db_host 
        }
        env { 
          name  = "DB_USER"
          value = var.db_user 
        }
        env { 
          name  = "DB_PASS"
          value = var.db_password 
        }
        env { 
          name  = "DB_NAME"
          value = var.db_name 
        }
        env { 
          name  = "TABLA"
          value = var.nombre_tabla 
        }
        env { 
          name  = "BUCKET"
          value = var.bucket_data_name 
        }
      }
    }
  }

  # El Job no puede crearse hasta que la imagen no esté subida
  depends_on = [null_resource.build_y_subir_docker]
}