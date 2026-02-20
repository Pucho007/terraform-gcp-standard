output "vpc_creada" {
  value = module.red_cliente.network_id
}
output "bucket_creado" {
  value = module.almacenamiento_cliente.bucket_url
}
output "dataset_creado" {
  value = module.datos_cliente.dataset_id
}