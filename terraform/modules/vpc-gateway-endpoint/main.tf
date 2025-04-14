resource "aws_vpc_endpoint" "this" {
  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.${var.region}.${var.service}"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = var.route_table_ids

}