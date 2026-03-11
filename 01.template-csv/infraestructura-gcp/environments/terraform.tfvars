# Variables globales
project_id        = "terraform-test-488010"
region            = "us-central1"

# Nombre bucket para albergar archivo de configuracion de terraform
state_bucket_name = "bucket-terraform-state-test-10"

# Nombre de bucket de cloud storage
app_bucket_name   = "bucket-terraform-test-10" 

# Dataset de Bigquery (no usar guiones)
dataset_name      = "dataset_terraform_test_10"

# Dataset de Bigquery DESTINO (DATAFORM) (no usar guiones)
dataset_destino_name = "dataset_transformado_vooxell_10"

# Tabla de Bigquery de destino
table_id = "tabla_vooxell" 

# Variables para la Orquestación
# Variables para Workflow
workflow_name         = "flujo-procesamiento-vooxell-10"
workflow_sa_id        = "robot-workflow-vooxell-10"

# Variables para Eventarc
eventarc_trigger_name = "trigger-archivos-bucket-10"
eventarc_sa_id        = "robot-eventarc-vooxell-10"


#Variables para Dataform
dataform_repo_name = "repo-transformaciones-vooxell-10"
dataform_sa_name   = "sa-dataform-vooxell-10"