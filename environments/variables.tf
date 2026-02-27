# Variables globales
variable "project_id" {}
variable "region" { default = "us-central1" }

# Nombre bucket para albergar archivo de configuracion de terraform
variable "state_bucket_name" {
  description = "Nombre del bucket de estado (usado por el bootstrap.sh)"
  type        = string
}

# Nombre de bucket de cloud storage
variable "app_bucket_name" {}

# Dataset de Bigquery
variable "dataset_name" {}

# Variables para la Orquestación
# Variables para Workflow
variable "workflow_name" { type = string }
variable "workflow_sa_id" { type = string }

# Variables para Eventarc
variable "eventarc_trigger_name" { type = string }
variable "eventarc_sa_id" { type = string }