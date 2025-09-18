# Databricks notebook source
# Instala dependências (no cluster)
%pip install -q datasets==2.20.0

# COMMAND ----------
import os
from datasets import load_dataset

# Widgets para parâmetros (funciona em Job e execução manual)
dbutils.widgets.text("dataset_name", "stanfordnlp/imdb", "HuggingFace dataset")
dbutils.widgets.text("s3_path", "", "S3 base path (ex: s3a://<bucket>/bronze/imdb)")
dbutils.widgets.text("write_format", "parquet", "write format (parquet/csv)")
dbutils.widgets.text("repartition", "8", "num partitions")

dataset_name = dbutils.widgets.get("dataset_name").strip() or "stanfordnlp/imdb"
s3_path = dbutils.widgets.get("s3_path").strip()
write_format = (dbutils.widgets.get("write_format") or "parquet").lower()
repartition = int(dbutils.widgets.get("repartition") or "8")

# Fallback para variáveis de ambiente quando não houver widget definido
if not s3_path:
    bucket = os.environ.get("S3_BUCKET")
    prefix = os.environ.get("S3_PREFIX", "bronze/imdb")
    if not bucket:
        raise ValueError(
            "Defina 's3_path' via widget (s3a://<bucket>/bronze/imdb) "
            "ou exporte S3_BUCKET (+ opcional S3_PREFIX)."
        )
    s3_path = f"s3a://{bucket}/{prefix}"

print(f"Dataset: {dataset_name}")
print(f"Destino S3: {s3_path} (formato: {write_format})")

# COMMAND ----------
# Carrega dataset do Hugging Face (precisa de internet no cluster)
ds = load_dataset(dataset_name)

# Grava cada split em uma pasta separada no S3
for split_name, split_ds in ds.items():
    n = len(split_ds)
    print(f"Split '{split_name}': {n} registros")

    # Converte para Pandas e então para Spark DataFrame
    pdf = split_ds.to_pandas()
    sdf = spark.createDataFrame(pdf).repartition(repartition)

    out_path = f"{s3_path.rstrip('/')}/{split_name}"
    if write_format == "csv":
        (
            sdf.write
            .mode("overwrite")
            .option("header", "true")
            .csv(out_path)
        )
    else:
        (
            sdf.write
            .mode("overwrite")
            .parquet(out_path)
        )
    print(f"Gravou em: {out_path}")
