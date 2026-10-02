variable "region" {
  type    = string
  default = "ap-south-1"
}
variable "environment" {
  type    = string
  default = "dev"
}
variable "db_password" {
  type      = string
  sensitive = true
}

variable "budget_limit" {
  description = "Monthly cost cap in USD for alerts."
  type        = string
  default     = "50"
}
variable "budget_email" {
  description = "Email for billing alerts."
  type        = string
  default     = "sayaksatpathi12@gmail.com"
}
