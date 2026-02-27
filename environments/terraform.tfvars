# Variables globales
project_id        = "terraform-test-488010"
region            = "us-central1"

# Nombre bucket para albergar archivo de configuracion de terraform
state_bucket_name = "bucket-terraform-state-test-8"

# Nombre de bucket de cloud storage
app_bucket_name   = "bucket-terraform-test-8" 

# Dataset de Bigquery (no usar guiones)
dataset_name      = "dataset_terraform_test_8"


# Variables para la Orquestación
# Variables para Workflow
workflow_name         = "flujo-procesamiento-vooxell-8"
workflow_sa_id        = "robot-workflow-vooxell-8"

# Variables para Eventarc
eventarc_trigger_name = "trigger-archivos-bucket-8"
eventarc_sa_id        = "robot-eventarc-vooxell-8"