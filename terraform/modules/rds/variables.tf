variable "name" { type = string }
variable "engine_version" {
  type    = string
  default = "16"
}
variable "instance_class" {
  type    = string
  default = "db.t3.micro"
}
variable "allocated_storage" {
  type    = number
  default = 20
}
variable "db_name" {
  type    = string
  default = "opsforge"
}
variable "username" {
  type    = string
  default = "opsforge"
}
variable "password" {
  type      = string
  sensitive = true
}
variable "multi_az" {
  type    = bool
  default = true
}
variable "subnet_ids" { type = list(string) }
variable "security_group_ids" {
  type    = list(string)
  default = []
}
variable "backup_retention_days" {
  type    = number
  default = 7
}
variable "skip_final_snapshot" {
  type    = bool
  default = true
}
variable "tags" {
  type    = map(string)
  default = {}
}

variable "deletion_protection" {
  type    = bool
  default = true
}
