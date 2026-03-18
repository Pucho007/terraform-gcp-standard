output "resumen_despliegue" {
  description = "Resumen de los recursos creados para el cliente"
  value = {
    cuenta_de_servicio_extraccion   = module.iam.sa_extraccion_email
    cuenta_de_servicio_orquestacion = module.iam.sa_orquestacion_email
    bucket_para_csv      = module.storage.bucket_data_url
    bucket_para_reglas   = module.storage.bucket_config_url
    dataset_crudo        = module.bigquery.dataset_staging_id
    dataset_limpio       = module.bigquery.dataset_prod_id
    url_funcion_calidad  = module.calidad.function_uri
  }
}