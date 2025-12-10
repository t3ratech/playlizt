output "frontend_url" {
  description = "URL of the Frontend Service"
  value       = google_cloud_run_v2_service.frontend.uri
}

output "api_gateway_url" {
  description = "URL of the API Gateway"
  value       = google_cloud_run_v2_service.playlizt_api_gateway.uri
}

output "auth_service_url" {
  description = "URL of the Auth Service"
  value       = google_cloud_run_v2_service.playlizt_authentication.uri
}

output "content_service_url" {
  description = "URL of the Content Service"
  value       = google_cloud_run_v2_service.playlizt_content_api.uri
}

output "playback_service_url" {
  description = "URL of the Playback Service"
  value       = google_cloud_run_v2_service.playlizt_playback.uri
}

output "ai_service_url" {
  description = "URL of the AI Service"
  value       = google_cloud_run_v2_service.playlizt_content_processing.uri
}
