provider "google" {
  project = var.project_id
  region  = var.region
}

module "iam" {
  source     = "../modules/iam"
  project_id = var.project_id
  sa_name    = var.sa_name
}

module "storage" {
  source             = "../modules/storage"
  region             = var.region
  bucket_data_name   = var.bucket_data_name
  bucket_config_name = var.bucket_config_name
}

module "bigquery" {
  source               = "../modules/bigquery"
  region               = var.region
  dataset_staging_name = var.dataset_staging_name
  dataset_prod_name    = var.dataset_prod_name
}

module "extraccion" {
  source              = "../modules/extraccion"
  region              = var.region
  project_id          = var.project_id
  repo_docker_name    = var.repo_docker_name
  job_extraccion_name = var.job_extraccion_name
  db_host             = var.db_host
  bucket_data_name    = var.bucket_data_name
  sa_email            = module.iam.sa_email # Usamos el correo recién creado

  # Variables de conexión a la base de datos
  db_host             = var.db_host
  db_user             = var.db_user
  db_password         = var.db_password
  db_name             = var.db_name
  nombre_tabla        = var.nombre_tabla
}

module "calidad" {
  source                = "../modules/calidad"
  project_id            = var.project_id
  region                = var.region
  function_calidad_name = var.function_calidad_name
  bucket_config_name    = var.bucket_config_name
  sa_email              = module.iam.sa_email
  depends_on            = [module.storage]
}

module "orquestacion" {
  source         = "../modules/orquestacion"
  region         = var.region
  project_id     = var.project_id
  workflow_name  = var.workflow_name
  scheduler_name = var.scheduler_name
  sa_email       = module.iam.sa_email

  #Variables del workflow
  dataset_staging_name = var.dataset_staging_name
  nombre_tabla         = var.nombre_tabla
  bucket_data_name     = var.bucket_data_name
}