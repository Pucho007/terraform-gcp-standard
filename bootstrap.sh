#!/bin/bash
# Archivo: bootstrap.sh

# 1. Definimos dónde está el archivo del cliente
TFVARS_FILE="environments/terraform.tfvars"

echo "Leyendo configuración desde $TFVARS_FILE..."

# 2. Extraemos las variables automáticamente (quitando espacios y comillas)
PROJECT_ID=$(grep '^project_id' $TFVARS_FILE | awk -F'=' '{print $2}' | tr -d ' "' | tr -d '\r')
REGION=$(grep '^region' $TFVARS_FILE | awk -F'=' '{print $2}' | tr -d ' "' | tr -d '\r')
STATE_BUCKET_NAME=$(grep '^state_bucket_name' $TFVARS_FILE | awk -F'=' '{print $2}' | tr -d ' "' | tr -d '\r')

# Validamos que no estén vacías por si el cliente olvidó llenarlas
if [ -z "$PROJECT_ID" ] || [ -z "$STATE_BUCKET_NAME" ]; then
    echo "Error: No se pudo leer project_id o state_bucket_name del archivo .tfvars"
    exit 1
fi

echo "Iniciando preparación para el proyecto: $PROJECT_ID en $REGION"

# Encender los interruptores (APIs) de Google Cloud
echo "🔌 Habilitando APIs necesarias (esto puede tomar unos 10-20 segundos)..."
gcloud services enable \
  compute.googleapis.com \
  workflows.googleapis.com \
  eventarc.googleapis.com \
  pubsub.googleapis.com \
  dataform.googleapis.com \
  --project=$PROJECT_ID

# 3. Crear el bucket de estado si no existe
if gcloud storage ls gs://$STATE_BUCKET_NAME --project=$PROJECT_ID >/dev/null 2>&1; then
    echo "El bucket de estado ($STATE_BUCKET_NAME) ya existe. Saltando creación..."
else
    echo "Creando bucket de estado: $STATE_BUCKET_NAME..."
    gcloud storage buckets create gs://$STATE_BUCKET_NAME --project=$PROJECT_ID --location=$REGION
    gcloud storage buckets update gs://$STATE_BUCKET_NAME --versioning
fi

# 4. Iniciar Terraform
echo "Inicializando Terraform..."
cd environments/
terraform init -backend-config="bucket=$STATE_BUCKET_NAME"

echo "¡Entorno listo! Ya puedes ejecutar 'terraform plan' y 'terraform apply'."