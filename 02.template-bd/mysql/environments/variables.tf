variable "project_id" { type = string }
variable "region" { type = string }

# Storage Terraform
variable "state_bucket_name" { type = string }

# IAM 
variable "sa_name" { type = string }

# Storage
variable "bucket_data_name" { type = string }
variable "bucket_config_name" { type = string }

# BigQuery
variable "dataset_staging_name" { type = string }
variable "dataset_prod_name" { type = string }

# Extracción (Nombres exactos)
variable "repo_docker_name" { type = string }
variable "job_extraccion_name" { type = string }

# Calidad (Nombres exactos)
variable "function_calidad_name" { type = string }

# Orquestación (Nombres exactos)
variable "workflow_name" { type = string }
variable "scheduler_name" { type = string }

# Base de Datos
variable "db_host" { type = string }
variable "db_user" { type = string }
variable "db_password" {
  type      = string
  sensitive = true
}
variable "db_name" { type = string }

# El nombre de la tabla destino en BigQuery
variable "nombre_tabla" { type = string }