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
  dataset_id = "fees"
  location   = var.region

  depends_on = [google_project_service.bigquery]
}