# import os
# import pandas as pd
# from sqlalchemy import create_engine
# from google.cloud import storage

# def extraer_datos():
#     # 1. Leer las credenciales inyectadas por Terraform
#     db_host = os.environ['DB_HOST']
#     db_user = os.environ['DB_USER']
#     db_pass = os.environ['DB_PASS']
#     db_port = os.environ['DB_PORT']
#     db_name = os.environ['DB_NAME']
#     tabla   = os.environ['TABLA']
#     bucket_name = os.environ['BUCKET']
    
#     # --- ¡NUEVO! Leemos el nombre del archivo (con un valor por defecto por si acaso) ---
#     nombre_archivo = os.environ.get('ARCHIVO_CSV', 'extraccion_db.csv')

#     print(f"Iniciando extracción de la tabla: {tabla} desde MySQL")

#     # 2. Conectarse a MySQL usando SQLAlchemy y PyMySQL
#     conexion_str = f"mysql+pymysql://{db_user}:{db_pass}@{db_host}:{db_port}/{db_name}"
#     engine = create_engine(conexion_str)

#     # 3. Extraer la data usando Pandas
#     query = f"SELECT * FROM {tabla};"
    
#     df = pd.read_sql_query(query, engine)

#     # 4. Guardar temporalmente usando la NUEVA VARIABLE
#     archivo_local = f"/tmp/{nombre_archivo}"
#     df.to_csv(archivo_local, index=False)
#     print(f"Datos extraídos de MySQL: {len(df)} filas.")

#     # 5. Subir el CSV al Bucket de Ingesta de GCP
#     storage_client = storage.Client()
#     bucket = storage_client.bucket(bucket_name)
    
#     # Subimos el archivo con su NUEVO NOMBRE dinámico
#     blob = bucket.blob(nombre_archivo)
#     blob.upload_from_filename(archivo_local)

#     print(f"Archivo subido exitosamente a gs://{bucket_name}/{nombre_archivo}")

# if __name__ == "__main__":
#     extraer_datos()