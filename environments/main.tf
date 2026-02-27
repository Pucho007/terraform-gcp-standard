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
  dataset_id = var.dataset_id
  table_id   = var.table_id

  depends_on            = [module.almacenamiento_cliente] 
}