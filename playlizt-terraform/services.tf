# Authentication Service (playlizt-authentication)
resource "google_cloud_run_v2_service" "playlizt_authentication" {
  name     = "playlizt-authentication"
  location = var.region
  ingress  = "INGRESS_TRAFFIC_ALL"

  template {
    containers {
      image = "${var.region}-docker.pkg.dev/${var.project_id}/playlizt-repo/playlizt-authentication:${var.image_tag}"
      ports {
        container_port = 4081
      }
      resources {
        limits = {
          cpu    = "1000m"
          memory = "1024Mi"
        }
      }
      env {
        name  = "SPRING_CLOUD_GCP_SQL_INSTANCE_CONNECTION_NAME"
        value = google_sql_database_instance.playlizt_db.connection_name
      }
      env {
        name  = "SPRING_CLOUD_GCP_SQL_DATABASE_NAME"
        value = google_sql_database.database.name
      }
      env {
        name  = "SPRING_DATASOURCE_USERNAME"
        value = var.db_user
      }
      env {
        name  = "SPRING_DATASOURCE_PASSWORD"
        value = var.db_password
      }
      env {
        name  = "SERVER_PORT"
        value = "4081"
      }
      env {
        name  = "JWT_SECRET"
        value = var.jwt_secret
      }
      env {
        name  = "JWT_EXPIRATION_MS"
        value = var.jwt_expiration_ms
      }
      env {
        name  = "JWT_REFRESH_EXPIRATION_MS"
        value = var.jwt_refresh_expiration_ms
      }
      env {
        name  = "EUREKA_CLIENT_ENABLED"
        value = "false" 
      }
      env {
        name  = "SPRING_JPA_PROPERTIES_HIBERNATE_DEFAULT_SCHEMA"
        value = "playlizt_authentication"
      }
    }
    
    volumes {
      name = "cloudsql"
      cloud_sql_instance {
        instances = [google_sql_database_instance.playlizt_db.connection_name]
      }
    }
  }
  deletion_protection = false
  depends_on = [google_artifact_registry_repository.playlizt_repo, google_sql_database_instance.playlizt_db, google_project_service.run_api]
}

# Content Service (playlizt-content-api)
resource "google_cloud_run_v2_service" "playlizt_content_api" {
  name     = "playlizt-content-api"
  location = var.region
  ingress  = "INGRESS_TRAFFIC_ALL"

  template {
    containers {
      image = "${var.region}-docker.pkg.dev/${var.project_id}/playlizt-repo/playlizt-content-api:${var.image_tag}"
      ports {
        container_port = 4082
      }
      resources {
        limits = {
          cpu    = "1000m"
          memory = "1024Mi"
        }
      }
      env {
        name  = "SPRING_CLOUD_GCP_SQL_INSTANCE_CONNECTION_NAME"
        value = google_sql_database_instance.playlizt_db.connection_name
      }
      env {
        name  = "SPRING_CLOUD_GCP_SQL_DATABASE_NAME"
        value = google_sql_database.database.name
      }
      env {
        name  = "SPRING_DATASOURCE_USERNAME"
        value = var.db_user
      }
      env {
        name  = "SPRING_DATASOURCE_PASSWORD"
        value = var.db_password
      }
      env {
        name  = "SERVER_PORT"
        value = "4082"
      }
      env {
        name  = "EUREKA_CLIENT_ENABLED"
        value = "false" 
      }
      env {
        name  = "GEMINI_API_KEY"
        value = var.gemini_api_key
      }
      env {
        name  = "SPRING_JPA_PROPERTIES_HIBERNATE_DEFAULT_SCHEMA"
        value = "playlizt_content"
      }
      env {
        name  = "SPRING_JPA_PROPERTIES_HIBERNATE_HBM2DDL_CREATE_NAMESPACES"
        value = "true"
      }
      env {
        name  = "FORCE_DEPLOY"
        value = "1"
      }
    }
    volumes {
      name = "cloudsql"
      cloud_sql_instance {
        instances = [google_sql_database_instance.playlizt_db.connection_name]
      }
    }
  }
  deletion_protection = false
  depends_on = [google_artifact_registry_repository.playlizt_repo, google_sql_database_instance.playlizt_db, google_project_service.run_api]
}

# Playback Service (playlizt-playback)
resource "google_cloud_run_v2_service" "playlizt_playback" {
  name     = "playlizt-playback"
  location = var.region
  ingress  = "INGRESS_TRAFFIC_ALL"

  template {
    containers {
      image = "${var.region}-docker.pkg.dev/${var.project_id}/playlizt-repo/playlizt-playback:${var.image_tag}"
      ports {
        container_port = 4083
      }
      resources {
        limits = {
          cpu    = "1000m"
          memory = "1024Mi"
        }
      }
      env {
        name  = "SPRING_CLOUD_GCP_SQL_INSTANCE_CONNECTION_NAME"
        value = google_sql_database_instance.playlizt_db.connection_name
      }
      env {
        name  = "SPRING_CLOUD_GCP_SQL_DATABASE_NAME"
        value = google_sql_database.database.name
      }
      env {
        name  = "SPRING_DATASOURCE_USERNAME"
        value = var.db_user
      }
      env {
        name  = "SPRING_DATASOURCE_PASSWORD"
        value = var.db_password
      }
      env {
        name  = "SERVER_PORT"
        value = "4083"
      }
      env {
        name  = "EUREKA_CLIENT_ENABLED"
        value = "false" 
      }
      env {
        name  = "SPRING_JPA_PROPERTIES_HIBERNATE_DEFAULT_SCHEMA"
        value = "playlizt_playback"
      }
    }
    volumes {
      name = "cloudsql"
      cloud_sql_instance {
        instances = [google_sql_database_instance.playlizt_db.connection_name]
      }
    }
  }
  deletion_protection = false
  depends_on = [google_artifact_registry_repository.playlizt_repo, google_sql_database_instance.playlizt_db, google_project_service.run_api]
}

# AI Service (playlizt-content-processing)
resource "google_cloud_run_v2_service" "playlizt_content_processing" {
  name     = "playlizt-content-processing"
  location = var.region
  ingress  = "INGRESS_TRAFFIC_ALL"

  template {
    containers {
      image = "${var.region}-docker.pkg.dev/${var.project_id}/playlizt-repo/playlizt-content-processing:${var.image_tag}"
      ports {
        container_port = 4084
      }
      resources {
        limits = {
          cpu    = "1000m"
          memory = "1024Mi"
        }
      }
      env {
        name  = "SERVER_PORT"
        value = "4084"
      }
      env {
        name  = "EUREKA_CLIENT_ENABLED"
        value = "false" 
      }
      env {
        name  = "GEMINI_API_KEY"
        value = var.gemini_api_key
      }
    }
  }
  deletion_protection = false
  depends_on = [google_artifact_registry_repository.playlizt_repo, google_project_service.run_api]
}

# API Gateway (playlizt-api-gateway, Spring Cloud Gateway)
resource "google_cloud_run_v2_service" "playlizt_api_gateway" {
  name     = "playlizt-api-gateway"
  location = var.region
  ingress  = "INGRESS_TRAFFIC_ALL"

  template {
    containers {
      image = "${var.region}-docker.pkg.dev/${var.project_id}/playlizt-repo/playlizt-api-gateway:${var.image_tag}"
      ports {
        container_port = 4080
      }
      resources {
        limits = {
          cpu    = "1000m"
          memory = "512Mi" # Gateway is lighter
        }
      }
      env {
        name  = "SERVER_PORT"
        value = "4080"
      }
      env {
        name  = "AUTH_SERVICE_URL"
        value = google_cloud_run_v2_service.playlizt_authentication.uri
      }
      env {
        name  = "CONTENT_SERVICE_URL"
        value = google_cloud_run_v2_service.playlizt_content_api.uri
      }
      env {
        name  = "PLAYBACK_SERVICE_URL"
        value = google_cloud_run_v2_service.playlizt_playback.uri
      }
      env {
        name  = "AI_SERVICE_URL"
        value = google_cloud_run_v2_service.playlizt_content_processing.uri
      }
      env {
        name  = "EUREKA_CLIENT_ENABLED"
        value = "false" 
      }
    }
  }
  deletion_protection = false
  depends_on = [
    google_cloud_run_v2_service.playlizt_authentication, 
    google_cloud_run_v2_service.playlizt_content_api,
    google_cloud_run_v2_service.playlizt_playback,
    google_cloud_run_v2_service.playlizt_content_processing,
    google_project_service.run_api
  ]
}

# Frontend (Flutter Web)
resource "google_cloud_run_v2_service" "frontend" {
  name     = "playlizt-frontend"
  location = var.region
  ingress  = "INGRESS_TRAFFIC_ALL"

  template {
    containers {
      image = "${var.region}-docker.pkg.dev/${var.project_id}/playlizt-repo/playlizt-frontend:${var.image_tag}"
      ports {
        container_port = 80
      }
      resources {
        limits = {
          cpu    = "1000m"
          memory = "512Mi"
        }
      }
    }
  }
  deletion_protection = false
  depends_on = [google_project_service.run_api]
}

# Allow unauthenticated access to Frontend
resource "google_cloud_run_service_iam_member" "frontend_public" {
  location = google_cloud_run_v2_service.frontend.location
  service  = google_cloud_run_v2_service.frontend.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

# Allow unauthenticated access to Gateway (Auth handled by Gateway/Services)
resource "google_cloud_run_service_iam_member" "gateway_public" {
  location = google_cloud_run_v2_service.playlizt_api_gateway.location
  service  = google_cloud_run_v2_service.playlizt_api_gateway.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

# Allow Gateway (Default Compute SA) to invoke Backend Services
resource "google_cloud_run_service_iam_member" "auth_invoker" {
  location = google_cloud_run_v2_service.playlizt_authentication.location
  service  = google_cloud_run_v2_service.playlizt_authentication.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

resource "google_cloud_run_service_iam_member" "content_invoker" {
  location = google_cloud_run_v2_service.playlizt_content_api.location
  service  = google_cloud_run_v2_service.playlizt_content_api.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

resource "google_cloud_run_service_iam_member" "playback_invoker" {
  location = google_cloud_run_v2_service.playlizt_playback.location
  service  = google_cloud_run_v2_service.playlizt_playback.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

resource "google_cloud_run_service_iam_member" "ai_invoker" {
  location = google_cloud_run_v2_service.playlizt_content_processing.location
  service  = google_cloud_run_v2_service.playlizt_content_processing.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}
