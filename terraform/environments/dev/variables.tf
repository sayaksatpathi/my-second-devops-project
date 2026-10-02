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
