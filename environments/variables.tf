variable "project_id" {}
variable "region" { default = "us-central1" }
variable "state_bucket_name" {
  description = "Nombre del bucket de estado (usado por el bootstrap.sh)"
  type        = string
}
variable "app_bucket_name" {}
variable "vpc_name" {}
variable "dataset_name" {}