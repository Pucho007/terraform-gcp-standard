provider "google" {
  project = var.project_id
  region  = var.region
}

# 3. Llamada al Módulo Storage
module "almacenamiento_cliente" {
  source        = "../modules/storage"
  project_id    = var.project_id
  region        = var.region
  bucket_name   = var.app_bucket_name
  common_labels = { environment = "prod", managed_by = "terraform" }
}

# 4. Llamada al Módulo BigQuery (Dataset)
module "datos_cliente" {
  source        = "../modules/bigquery"
  project_id    = var.project_id
  region        = var.region
  dataset_name  = var.dataset_name
  dataset_destino_name = var.dataset_destino_name
  common_labels = { environment = "prod", managed_by = "terraform" }
}

# 5. Llamada al Módulo Orquestación
module "orquestacion_cliente" {
  source                = "../modules/orquestacion"
  project_id            = var.project_id
  region                = var.region
  bucket_name           = var.app_bucket_name
  workflow_yaml_path    = "${path.root}/../src/procesamiento.yaml"
  
  # variables dinamicas
  workflow_name         = var.workflow_name
  workflow_sa_id        = var.workflow_sa_id
  eventarc_trigger_name = var.eventarc_trigger_name
  eventarc_sa_id        = var.eventarc_sa_id
  
  #Variables que van hacia el yaml
  dataset_name = var.dataset_name
  table_id   = var.table_id

  depends_on            = [module.almacenamiento_cliente] 

  #Variables Dataform
  dataform_repo_name = var.dataform_repo_name
}

# 6. Llamada al módulo de Dataform
module "dataform_cliente" {
  source             = "../modules/dataform"
  project_id         = var.project_id
  region             = var.region
  repository_name    = var.dataform_repo_name
  dataform_sa_name   = var.dataform_sa_name
}