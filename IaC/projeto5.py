%pip install -q datasets==2.20.0

# COMMAND ----------
import os
from datasets import load_dataset

# Parâmetros mínimos
dbutils.widgets.text("dataset_name", "stanfordnlp/imdb", "Dataset")
dbutils.widgets.text("s3_path", "", "S3 destination path")

dataset_name = dbutils.widgets.get("dataset_name").strip() or "stanfordnlp/imdb"
s3_path = dbutils.widgets.get("s3_path").strip()

if not s3_path:
    bucket = os.environ.get("S3_BUCKET")
    prefix = os.environ.get("S3_PREFIX", "bronze/imdb")
    if not bucket:
        raise ValueError("Defina 's3_path' via widget ou exporte S3_BUCKET (+ opcional S3_PREFIX).")
    s3_path = f"s3a://{bucket}/{prefix}"

# Carrega o dataset do Hugging Face
ds = load_dataset(dataset_name)

# Une todos os splits em um único DataFrame Spark e grava em Parquet
sdf_merged = None
for _, split in ds.items():
    pdf = split.to_pandas()
    sdf_split = spark.createDataFrame(pdf)
    sdf_merged = sdf_split if sdf_merged is None else sdf_merged.unionByName(sdf_split, allowMissingColumns=True)

sdf_merged.write.mode("overwrite").parquet(s3_path)
