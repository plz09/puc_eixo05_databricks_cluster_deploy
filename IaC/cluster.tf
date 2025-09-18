variable "cluster_name" {
  description = "Nome do cluster."
  type        = string
  default     = "PUC Cluster"
}

variable "cluster_autotermination_minutes" {
  description = "Quantos minutos antes de encerrar automaticamente devido à inatividade."
  type        = number
  default     = 60
}

variable "cluster_num_workers" {
  description = "Número de workers."
  type        = number
  default     = 1
}

# Cria o cluster com a menor quantidade de recursos permitida
data "databricks_node_type" "smallest" {
  local_disk = true
}

# Usa o Databricks Runtime mais recente
# Long Term Support (LTS) version.
data "databricks_spark_version" "latest_lts" {
  long_term_support = true
}

resource "databricks_cluster" "puc_cluster" {
  cluster_name            = var.cluster_name
  node_type_id            = data.databricks_node_type.smallest.id
  spark_version           = data.databricks_spark_version.latest_lts.id
  autotermination_minutes = var.cluster_autotermination_minutes
  num_workers             = var.cluster_num_workers

  aws_attributes {
    instance_profile_arn = databricks_instance_profile.cluster_profile.id
  }
}

output "cluster_url" {
 value = databricks_cluster.puc_cluster.url
}


