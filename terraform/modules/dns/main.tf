data "aws_route53_zone" "public" {
  name         = var.domain_name
  private_zone = false
}

# Route53 - Private Zone
resource "aws_route53_zone" "private" {
  name = var.private_zone_name

  vpc {
    vpc_id = var.vpc_id
  }

  tags = {
    Name = "${var.private_zone_name}-private-zone"
  }
}