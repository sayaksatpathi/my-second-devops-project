variable "name" { type = string }
variable "node_type" {
  type    = string
  default = "cache.t3.micro"
}
variable "num_nodes" {
  type    = number
  default = 2
}
variable "subnet_ids" { type = list(string) }
variable "security_group_ids" {
  type    = list(string)
  default = []
}
variable "tags" {
  type    = map(string)
  default = {}
}
