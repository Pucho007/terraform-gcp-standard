# =======================================================
# 1. CREACIÓN DE LAS CUENTAS DE SERVICIO (Los personajes)
# =======================================================

# Personaje A: El Orquestador (Workflows)
resource "google_service_account" "sa_orquestacion" {
  account_id   = var.sa_orquestacion_id
  display_name = "Service Account para Cloud Workflows"
}

# Personaje B: El Extractor (Cloud Run)
resource "google_service_account" "sa_extraccion" {
  account_id   = var.sa_extraccion_id
  display_name = "Service Account para Extraccion DB"
}

# =======================================================
# 2. PERMISOS DEL ORQUESTADOR (Workflows)
# =======================================================
# Permiso para invocar Cloud Run (Extracción)
resource "google_project_iam_member" "orquestador_run" {
  project = var.project_id
  role    = "roles/run.invoker"
  member  = "serviceAccount:${google_service_account.sa_orquestacion.email}"
}

# Permiso para meter datos en BigQuery
resource "google_project_iam_member" "orquestador_bq" {
  project = var.project_id
  role    = "roles/bigquery.dataEditor"
  member  = "serviceAccount:${google_service_account.sa_orquestacion.email}"
}

# Permiso para invocar la Cloud Function (Calidad)
resource "google_project_iam_member" "orquestador_fn" {
  project = var.project_id
  role    = "roles/cloudfunctions.invoker"
  member  = "serviceAccount:${google_service_account.sa_orquestacion.email}"
}

# Permiso para que el Cloud Scheduler pueda invocar/ejecutar el Workflow
resource "google_project_iam_member" "orquestador_workflows" {
  project = var.project_id
  role    = "roles/workflows.invoker"
  member  = "serviceAccount:${google_service_account.sa_orquestacion.email}"
}

# Permiso para que el Orquestador pueda ver el progreso del Cloud Run Job
resource "google_project_iam_member" "orquestador_run_viewer" {
  project = var.project_id
  role    = "roles/run.viewer"
  member  = "serviceAccount:${google_service_account.sa_orquestacion.email}"
}

# Permiso para que el Orquestador pueda ejecutar trabajos (Jobs) de carga en BigQuery
resource "google_project_iam_member" "orquestador_bq_jobuser" {
  project = var.project_id
  role    = "roles/bigquery.jobUser"
  member  = "serviceAccount:${google_service_account.sa_orquestacion.email}"
}

# Permiso para que el Orquestador (BigQuery) pueda leer el CSV desde el Bucket
resource "google_project_iam_member" "orquestador_storage_viewer" {
  project = var.project_id
  role    = "roles/storage.objectViewer"
  member  = "serviceAccount:${google_service_account.sa_orquestacion.email}"
}

# =======================================================
# 3. PERMISOS DEL EXTRACTOR (Cloud Run)
# =======================================================
# Solo necesita permiso para guardar el CSV en el Bucket de Storage
resource "google_project_iam_member" "extractor_storage" {
  project = var.project_id
  role    = "roles/storage.objectAdmin"
  member  = "serviceAccount:${google_service_account.sa_extraccion.email}"
}

# =======================================================
# 4. PERMISOS DEL ROBOT "ALBAÑIL" DE GOOGLE (Cloud Build)
# =======================================================
# Leemos el número de proyecto para identificar al albañil
data "google_project" "project" {
  project_id = var.project_id
}

# Permiso para leer el bucket temporal al construir el Docker
resource "google_project_iam_member" "build_storage" {
  project = var.project_id
  role    = "roles/storage.admin"
  member  = "serviceAccount:${data.google_project.project.number}-compute@developer.gserviceaccount.com"
}

# Permiso para guardar el Docker en Artifact Registry
resource "google_project_iam_member" "build_artifact" {
  project = var.project_id
  role    = "roles/artifactregistry.writer"
  member  = "serviceAccount:${data.google_project.project.number}-compute@developer.gserviceaccount.com"
}

# Este recurso espera 30 segundos tras crear los permisos del "albañil"
resource "time_sleep" "esperar_propagacion_iam" {
  create_duration = "30s"

  depends_on = [
    google_project_iam_member.build_storage,
    google_project_iam_member.build_artifact,
    google_project_iam_member.orquestador_workflows,
    google_project_iam_member.orquestador_run_viewer,
    google_project_iam_member.orquestador_bq_jobuser,
    google_project_iam_member.orquestador_storage_viewer,
    google_project_iam_member.orquestador_run,
    google_project_iam_member.orquestador_bq,
    google_project_iam_member.orquestador_fn,
    google_project_iam_member.extractor_storage
  ]
}

