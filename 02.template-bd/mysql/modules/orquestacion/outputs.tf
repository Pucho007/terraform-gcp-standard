output "workflow_id" {
  description = "ID del Workflow orquestador"
  value       = google_workflows_workflow.wf.id
}