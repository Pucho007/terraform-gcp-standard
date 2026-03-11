# 1. El Workflow Principal
resource "google_workflows_workflow" "wf" {
  name            = var.workflow_name
  region          = var.region
  service_account = var.sa_email
  
  # Inyectamos las variables de Terraform dentro del YAML
  source_contents = templatefile("../src/workflows/procesamiento.yaml", {
    project_id      = var.project_id
    region          = var.region
    dataset_staging = var.dataset_staging_name
    tabla           = var.nombre_tabla
    bucket_data     = var.bucket_data_name
  })
}

# 2. El Reloj (Scheduler) que despierta al Workflow
resource "google_cloud_scheduler_job" "cron" {
  name      = var.scheduler_name
  schedule  = "0 2 * * *"
  time_zone = "America/Lima"
  http_target {
    http_method = "POST"
    uri         = "https://workflowexecutions.googleapis.com/v1/projects/${var.project_id}/locations/${var.region}/workflows/${google_workflows_workflow.wf.name}/executions"
    oauth_token { service_account_email = var.sa_email }
  }
}