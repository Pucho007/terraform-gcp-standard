variable "project_id" { type = string }
variable "region" { type = string }
variable "repo_docker_name" { type = string }
variable "job_extraccion_name" { type = string }
variable "bucket_data_name" { type = string }
variable "sa_email" { type = string }

variable "db_host" { type = string }
variable "db_user" { type = string }
variable "db_password" {
  type      = string
  sensitive = true
}
variable "db_name" { type = string }
variable "nombre_tabla" { type = string }
