# Variables globales
project_id        = "terraform-test-488010"
region            = "us-central1"

# Nombre bucket para albergar archivo de configuracion de terraform
state_bucket_name = "bucket-terraform-state-test-7"

# Nombre de bucket de cloud storage
app_bucket_name   = "bucket-terraform-test-7" 

# Dataset de Bigquery (no usar guiones)
dataset_name      = "dataset_terraform_test_7"


# Variables para la Orquestación
# Variables para Workflow
workflow_name         = "flujo-procesamiento-vooxell_7"
workflow_sa_id        = "robot-workflow-vooxell_7"

# Variables para Eventarc
eventarc_trigger_name = "trigger-archivos-bucket_7"
eventarc_sa_id        = "robot-eventarc-vooxell_7"