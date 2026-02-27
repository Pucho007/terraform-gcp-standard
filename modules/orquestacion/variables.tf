variable "project_id" {}
variable "region" {}
variable "bucket_name" {}
variable "workflow_yaml_path" {}

# Nuevas variables que recibe el módulo
variable "workflow_name" {}
variable "workflow_sa_id" {}

variable "eventarc_trigger_name" {}
variable "eventarc_sa_id" {}

variable "dataset_id" {
  description = "El ID del dataset de BigQuery"
  type        = string
}

variable "table_id" {
  description = "El ID de la tabla de BigQuery"
  type        = string
}