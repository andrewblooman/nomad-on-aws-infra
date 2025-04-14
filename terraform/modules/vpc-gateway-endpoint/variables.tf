variable "vpc_id" {}
variable "region" {}
variable "service" {
  type        = string
  description = "Service name like 's3' or 'dynamodb'"
}
variable "route_table_ids" {
  type = list(string)
}
