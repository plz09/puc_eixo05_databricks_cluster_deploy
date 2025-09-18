variable "job_name" {
  description = "Nome do job."
  type        = string
  default     = "PUC Job"
}

variable "task_key" {
  description = "Nome da tarefa."
  type        = string
  default     = "puc_p5_task"
}

resource "databricks_job" "puc_job" {
  
  name = var.job_name
  
  task {
    task_key = var.task_key
    existing_cluster_id = databricks_cluster.puc_cluster.cluster_id
    
    notebook_task {
      notebook_path = databricks_notebook.puc_notebook.path
    }
  }
  
  email_notifications {
    on_success = [ data.databricks_current_user.me.user_name ]
    on_failure = [ data.databricks_current_user.me.user_name ]
  }
}

output "job_url" {
  value = databricks_job.puc_job.url
}
