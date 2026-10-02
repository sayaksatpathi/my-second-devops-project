variable "name" { type = string }
variable "limit_amount" {
  description = "Monthly budget cap in USD."
  type        = string
  default     = "50"
}
variable "notification_email" {
  description = "Email to alert when the budget threshold is crossed."
  type        = string
}
