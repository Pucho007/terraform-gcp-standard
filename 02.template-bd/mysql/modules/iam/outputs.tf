output "sa_orquestacion_email" {
  value = google_service_account.sa_orquestacion.email
}

output "sa_extraccion_email" {
  value = google_service_account.sa_extraccion.email
}

# Exportamos el ID de este reloj para que otros módulos puedan "escucharlo"
output "reloj_iam_id" {
  value = time_sleep.esperar_propagacion_iam.id
}