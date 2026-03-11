import os
import pandas as pd
from sqlalchemy import create_engine
from google.cloud import storage

def extraer_datos():
    # 1. Leer las credenciales inyectadas por Terraform (¡Igual que antes!)
    db_host = os.environ['DB_HOST']
    db_user = os.environ['DB_USER']
    db_pass = os.environ['DB_PASS']
    db_name = os.environ['DB_NAME']
    tabla   = os.environ['TABLA']
    bucket_name = os.environ['BUCKET']

    print(f"Iniciando extracción de la tabla: {tabla} desde MySQL")

    # 2. Conectarse a MySQL usando SQLAlchemy y PyMySQL
    # Formato: mysql+pymysql://usuario:password@host/base_de_datos
    conexion_str = f"mysql+pymysql://{db_user}:{db_pass}@{db_host}/{db_name}"
    engine = create_engine(conexion_str)

    # 3. Extraer la data usando Pandas
    query = f"SELECT * FROM {tabla};"
    
    # Pandas usa el "engine" para ir a MySQL, lanzar el SELECT y traer la data a la memoria
    df = pd.read_sql_query(query, engine)

    # 4. Guardar temporalmente en un archivo CSV local dentro del contenedor
    archivo_local = "/tmp/extraccion_db.csv"
    df.to_csv(archivo_local, index=False)
    print(f"Datos extraídos de MySQL: {len(df)} filas.")

    # 5. Subir el CSV al Bucket de Ingesta de GCP
    storage_client = storage.Client()
    bucket = storage_client.bucket(bucket_name)
    blob = bucket.blob("extraccion_db.csv")
    blob.upload_from_filename(archivo_local)

    print(f"Archivo subido exitosamente a gs://{bucket_name}/extraccion_db.csv")

if __name__ == "__main__":
    extraer_datos()