terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_project_service" "storage" {
  service            = "storage.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "bigquery" {
  service            = "bigquery.googleapis.com"
  disable_on_destroy = false
}

resource "google_storage_bucket" "raw" {
  name                        = "${var.project_id}-fees-raw"
  location                    = var.region
  uniform_bucket_level_access = true
  force_destroy               = false

  depends_on = [google_project_service.storage]
}

resource "google_bigquery_dataset" "fees" {
  dataset_id                 = var.dataset_id
  location                   = var.region
  delete_contents_on_destroy = false

  depends_on = [google_project_service.bigquery]
}

resource "google_bigquery_table" "raw_fees" {
  dataset_id = google_bigquery_dataset.fees.dataset_id
  table_id   = "raw_fees"

  schema = jsonencode([
    {
      name = "client_id"
      type = "STRING"
      mode = "NULLABLE"
    },
    {
      name = "client_nino"
      type = "STRING"
      mode = "NULLABLE"
    },
    {
      name = "adviser_id"
      type = "STRING"
      mode = "NULLABLE"
    },
    {
      name = "fee_date"
      type = "DATE"
      mode = "NULLABLE"
    },
    {
      name = "fee_amount"
      type = "NUMERIC"
      mode = "NULLABLE"
    }
  ])

  deletion_protection = false
}
