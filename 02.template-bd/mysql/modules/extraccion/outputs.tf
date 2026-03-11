output "job_id" {
  description = "ID del Cloud Run Job creado"
  value       = google_cloud_run_v2_job.job.id
}