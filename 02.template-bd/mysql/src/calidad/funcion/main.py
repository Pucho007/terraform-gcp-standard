import os
import json
import functions_framework
from google.cloud import bigquery, storage

@functions_framework.http
def main(request):
    try:
        # 1. Obtenemos el nombre del bucket de configuración desde las variables de entorno
        bucket_nombre = os.environ.get('BUCKET_CONFIG')
        if not bucket_nombre:
            return "Error: No se configuró la variable BUCKET_CONFIG", 500

        # 2. Conectarnos a Cloud Storage y leer el archivo JSON
        storage_client = storage.Client()
        bucket = storage_client.bucket(bucket_nombre)
        blob = bucket.blob('reglas_calidad.json')
        
        # Descargamos el contenido como texto y lo convertimos a diccionario de Python
        reglas_texto = blob.download_as_text()
        reglas = json.loads(reglas_texto)
        
        # 3. Extraemos las reglas del JSON
        tabla = reglas.get('tabla_destino')
        columnas_no_nulas = reglas.get('columnas_no_nulas', [])

        if not tabla or not columnas_no_nulas:
            return "El JSON de reglas está incompleto. Faltan tablas o columnas.", 400

        # 4. Armar la consulta SQL DINÁMICAMENTE
        # Si el JSON dice ["columna_id", "fecha"], esto arma: "columna_id IS NULL AND fecha IS NULL"
        condiciones_sql = " AND ".join([f"{col} IS NULL" for col in columnas_no_nulas])
        
        query = f"""
            DELETE FROM `{tabla}`
            WHERE {condiciones_sql};
        """
        
        print(f"Ejecutando SQL: {query}") # Para que quede guardado en los logs de GCP

        # 5. Ejecutamos la limpieza en BigQuery
        bq_client = bigquery.Client()
        bq_client.query(query).result() # result() asegura que espere a que termine

        return f"Limpieza exitosa. Se aplicaron las reglas del JSON a la tabla {tabla}", 200

    except Exception as e:
        return f"Error en el motor de calidad: {str(e)}", 500