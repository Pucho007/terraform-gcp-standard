provider "google" {
  project = var.project_id
  region  = var.region
}

# 2. Llamada al Módulo VPC
module "red_cliente" {
  source      = "../modules/vpc"
  project_id  = var.project_id
  region      = var.region
  vpc_name    = var.vpc_name
  subnet_name = "${var.vpc_name}-subnet-01"
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