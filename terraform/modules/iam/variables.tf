variable "name" { type = string }
variable "github_repo" {
  description = "owner/repo allowed to assume the role"
  type        = string
  default     = "sayaksatpathi/opsforge-platform"
}
variable "tags" {
  type    = map(string)
  default = {}
}
