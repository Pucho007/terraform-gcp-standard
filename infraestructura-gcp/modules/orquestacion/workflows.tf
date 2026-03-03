# El Robot del Workflow
resource "google_service_account" "workflow_sa" {
  account_id   = var.workflow_sa_id 
  display_name = "Robot para ejecutar Workflows"
  project      = var.project_id
}

# Sus 3 permisos (Storage Viewer, BQ Editor, BQ Job User)
resource "google_project_iam_member" "wf_storage_viewer" {
  project = var.project_id
  role    = "roles/storage.objectViewer"
  member  = "serviceAccount:${google_service_account.workflow_sa.email}"
}
resource "google_project_iam_member" "wf_bq_editor" {
  project = var.project_id
  role    = "roles/bigquery.dataEditor"
  member  = "serviceAccount:${google_service_account.workflow_sa.email}"
}
resource "google_project_iam_member" "wf_bq_jobuser" {
  project = var.project_id
  role    = "roles/bigquery.jobUser"
  member  = "serviceAccount:${google_service_account.workflow_sa.email}"
}

resource "google_project_iam_member" "wf_dataform_editor" {
  project = var.project_id
  role    = "roles/dataform.editor"
  member  = "serviceAccount:${google_service_account.workflow_sa.email}"
}

# El Workflow en sí
resource "google_workflows_workflow" "flujo_vooxell" {
  name            = var.workflow_name
  region          = var.region
  project         = var.project_id
  service_account = google_service_account.workflow_sa.email
  
  # Variables usadas en el yaml
  source_contents = templatefile(var.workflow_yaml_path, {
    mi_dataset_inyectado = var.dataset_name
    mi_tabla_inyectada   = var.table_id
    mi_region            = var.region
    mi_repo_dataform     = var.dataform_repo_name
  })

  depends_on = [
    google_project_iam_member.wf_storage_viewer,
    google_project_iam_member.wf_bq_editor,
    google_project_iam_member.wf_bq_jobuser,
    google_project_iam_member.wf_dataform_editor
  ]
}

