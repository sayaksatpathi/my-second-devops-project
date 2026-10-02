variable "name" { type = string }
variable "repositories" {
  type    = list(string)
  default = ["user-api", "order-api", "worker"]
}
variable "tags" {
  type    = map(string)
  default = {}
}
