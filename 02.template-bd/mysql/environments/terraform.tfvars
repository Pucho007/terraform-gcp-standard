project_id             = "terraform-test-488010"
region                 = "us-central1"

# Nombre bucket para albergar archivo de configuracion de terraform
state_bucket_name = "bucket-terraform-test-prueba"

# IAM (Solo el nombre, Terraform creará el correo)
sa_name                = "sa-vooxell-db-ingesta"

# Storage
bucket_data_name       = "vooxell-data-cruda-db"
bucket_config_name     = "vooxell-reglas-calidad"

# BigQuery
dataset_staging_name   = "vooxell_staging_db"
dataset_prod_name      = "vooxell_prod_db"

# Extracción (Nombres exactos)
repo_docker_name       = "vooxell-repo-extraccion"
job_extraccion_name    = "vooxell-job-db-extractor"

# Calidad (Nombres exactos)
function_calidad_name  = "vooxell-fn-calidad"

# Orquestación (Nombres exactos)
workflow_name          = "vooxell-flujo-db-bq"
scheduler_name         = "vooxell-cron-diario"

# Base de Datos
db_host                = "198.51.100.14"
db_user                = "usuario_lectura"
db_password            = "super_secreto_123"
db_name                = "ventas_db"

# El nombre de la tabla destino en BigQuery
nombre_tabla           = "tabla_clientes"