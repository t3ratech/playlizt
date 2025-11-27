output "frontend_url" {
  description = "URL of the Frontend Service"
  value       = google_cloud_run_v2_service.frontend.uri
}

output "api_gateway_url" {
  description = "URL of the API Gateway"
  value       = google_cloud_run_v2_service.api_gateway.uri
}

output "auth_service_url" {
  description = "URL of the Auth Service"
  value       = google_cloud_run_v2_service.auth_service.uri
}

output "content_service_url" {
  description = "URL of the Content Service"
  value       = google_cloud_run_v2_service.content_service.uri
}

output "playback_service_url" {
  description = "URL of the Playback Service"
  value       = google_cloud_run_v2_service.playback_service.uri
}

output "ai_service_url" {
  description = "URL of the AI Service"
  value       = google_cloud_run_v2_service.ai_service.uri
}
