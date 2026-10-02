variable "cluster_name" { type = string }
variable "kubernetes_version" {
  type    = string
  default = "1.31"
}
variable "vpc_id" { type = string }
variable "private_subnet_ids" { type = list(string) }
variable "instance_types" {
  type    = list(string)
  default = ["t3.medium"]
}
variable "node_min" {
  type    = number
  default = 1
}
variable "node_max" {
  type    = number
  default = 2
}
variable "node_desired" {
  type    = number
  default = 1
}
variable "tags" {
  type    = map(string)
  default = {}
}
