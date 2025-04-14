variable "vpc_id" {}
variable "region" {}
variable "service" {}
variable "subnet_ids" {
  type = list(string)
}
variable "security_group_ids" {
  type = list(string)
}
