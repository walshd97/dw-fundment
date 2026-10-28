variable "project_id" {
  type        = string
  description = "GCP project ID"
}

variable "dataset_id" {
  type        = string
  description = "BigQuery dataset ID"
  default     = "fees"
}

variable "region" {
  type    = string
  default = "europe-west2"
}