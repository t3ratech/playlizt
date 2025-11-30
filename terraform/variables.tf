variable "project_id" {
  description = "The Google Cloud Project ID"
  type        = string
}

variable "region" {
  description = "GCP Region"
  type        = string
  default     = "us-central1"
}

variable "db_user" {
  description = "Database User"
  type        = string
  default     = "playlizt"
}

variable "db_password" {
  description = "Database Password"
  type        = string
  sensitive   = true
}

variable "jwt_secret" {
  description = "JWT Secret Key"
  type        = string
  sensitive   = true
}

variable "jwt_expiration_ms" {
  description = "JWT Expiration in milliseconds"
  type        = string
  default     = "3600000"
}

variable "jwt_refresh_expiration_ms" {
  description = "JWT Refresh Expiration in milliseconds"
  type        = string
  default     = "86400000"
}

variable "gemini_api_key" {
  description = "Gemini API Key"
  type        = string
  sensitive   = true
}
