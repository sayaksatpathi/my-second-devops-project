variable "region" {
  description = "DR region (different from primary)."
  type        = string
  default     = "us-east-1"
}
variable "environment" {
  type    = string
  default = "dr"
}
variable "db_password" {
  type      = string
  sensitive = true
}
