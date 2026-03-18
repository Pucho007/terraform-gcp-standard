# 1. Usamos una versión oficial y ligera de Python como base
FROM python:3.10-slim

# 2. Le decimos a Docker que trabaje dentro de la carpeta /app en el contenedor
WORKDIR /app

# 3. Copiamos la lista de librerías desde tu PC al contenedor
COPY requirements.txt .

# 4. Instalamos las librerías necesarias para conectarnos a MySQL y GCP
RUN pip install --no-cache-dir -r requirements.txt

# 5. Copiamos tu script principal (main.py) adentro del contenedor
COPY main.py .

# 6. Esta es la orden final: "Cuando Cloud Run despierte, ejecuta este script"
CMD ["python", "main.py"]