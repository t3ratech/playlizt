terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.51.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

data "google_project" "project" {}

# Grant Cloud SQL Client role to default Compute Service Account (used by Cloud Run)
resource "google_project_iam_member" "cloud_run_sql_client" {
  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${data.google_project.project.number}-compute@developer.gserviceaccount.com"
}

# Enable required APIs
resource "google_project_service" "run_api" {
  service = "run.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "sqladmin_api" {
  service = "sqladmin.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "artifactregistry_api" {
  service = "artifactregistry.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "secretmanager_api" {
  service = "secretmanager.googleapis.com"
  disable_on_destroy = false
}

# Artifact Registry for Docker Images
resource "google_artifact_registry_repository" "playlizt_repo" {
  location      = var.region
  repository_id = "playlizt-repo"
  description   = "Docker repository for Playlizt services"
  format        = "DOCKER"
  depends_on    = [google_project_service.artifactregistry_api]
}

# Cloud SQL (PostgreSQL)
resource "google_sql_database_instance" "playlizt_db" {
  name             = "playlizt-db-instance-${random_id.db_suffix.hex}"
  database_version = "POSTGRES_17" 
  region           = var.region
  depends_on       = [google_project_service.sqladmin_api]

  settings {
    tier = "db-custom-1-3840" # Smallest dedicated instance supported by Enterprise edition
    edition = "ENTERPRISE" # Explicitly set Standard Enterprise edition
    ip_configuration {
      ipv4_enabled = true 
    }
  }
  deletion_protection = false 
}

resource "random_id" "db_suffix" {
  byte_length = 4
}

resource "google_sql_database" "database" {
  name     = "playlizt"
  instance = google_sql_database_instance.playlizt_db.name
}

resource "google_sql_user" "users" {
  name     = var.db_user
  instance = google_sql_database_instance.playlizt_db.name
  password = var.db_password
}
