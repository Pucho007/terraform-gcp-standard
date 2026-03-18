project_id             = "terraform-test-488010"
region                 = "us-central1"

# Nombre bucket para albergar archivo de configuracion de terraform
state_bucket_name = "vooxell-terraform-state-prueba-3"

# IAM (Solo el nombre, Terraform creará el correo)
sa_orquestacion_id = "sa-cliente-orquestacion-3"
sa_extraccion_id   = "sa-cliente-extraccion-3"

# Storage
bucket_data_name       = "vooxell-data-cruda-db-3"
bucket_config_name     = "vooxell-reglas-calidad-3"

# BigQuery
dataset_staging_name   = "vooxell_staging_db_3"
dataset_prod_name      = "vooxell_prod_db_3"

# Extracción (Nombres exactos)
repo_docker_name       = "vooxell-repo-extraccion-3"
job_extraccion_name    = "vooxell-job-db-extractor-3"

# Calidad (Nombres exactos)
function_calidad_name  = "vooxell-fn-calidad-3"

# Orquestación (Nombres exactos)
workflow_name          = "vooxell-flujo-db-bq-3"
# scheduler_name         = "vooxell-cron-diario-3"

# Base de Datos
db_host                = "136.111.122.229"
db_user                = "RETAIL_DB"
db_password            = "Ventas2026_Test!"
db_name                = "XE"
db_port                = "1521" 

# # El nombre de la tabla destino en BigQuery
# nombre_tabla           = "transacciones_clientes"

# # Nombre del archivo CSV que se generará en el bucket de ingesta
# nombre_archivo_csv = "data_transacciones_diarias.csv"