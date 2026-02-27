# El Robot de Eventarc
resource "google_service_account" "eventarc_sa" {
  account_id   = var.eventarc_sa_id 
  display_name = "Robot de Eventarc"
  project      = var.project_id
}

# Permiso para invocador de Workflows
resource "google_project_iam_member" "eventarc_invoker" {
  project = var.project_id
  role    = "roles/workflows.invoker"
  member  = "serviceAccount:${google_service_account.eventarc_sa.email}"
}

# Permiso para ESCUCHAR los eventos del bucket
resource "google_project_iam_member" "eventarc_receiver" {
  project = var.project_id
  role    = "roles/eventarc.eventReceiver"
  member  = "serviceAccount:${google_service_account.eventarc_sa.email}"
}

# El Trigger
resource "google_eventarc_trigger" "storage_trigger" {
  name     = var.eventarc_trigger_name
  location = var.region
  project  = var.project_id

  matching_criteria {
    attribute = "type"
    value     = "google.cloud.storage.object.v1.finalized"
  }
  matching_criteria {
    attribute = "bucket"
    value     = var.bucket_name
  }

  service_account = google_service_account.eventarc_sa.email

  destination {
    workflow = google_workflows_workflow.flujo_vooxell.id
  }

  depends_on = [
    google_project_iam_member.eventarc_invoker,
    google_project_iam_member.eventarc_receiver
  ]
}