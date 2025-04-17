# VPC Link for API Gateway
resource "aws_apigatewayv2_vpc_link" "nomad" {
  name               = "nomad-vpc-link"
  subnet_ids         = var.private_subnets
  security_group_ids = [aws_security_group.api_gateway_vpc_link.id]
}

# Security Group for VPC Link
resource "aws_security_group" "api_gateway_vpc_link" {
  name        = "api-gateway-vpc-link-sg"
  description = "Security group for API Gateway VPC Link"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "api-gateway-vpc-link-sg"
  }
}

# API Gateway
resource "aws_apigatewayv2_api" "nomad" {
  name          = "nomad-api"
  protocol_type = "HTTP"
}

# API Gateway Stage
resource "aws_apigatewayv2_stage" "nomad" {
  api_id      = aws_apigatewayv2_api.nomad.id
  name        = "$default"
  auto_deploy = true
}

# API Gateway Domain
resource "aws_apigatewayv2_domain_name" "api" {
  domain_name = var.api_domain

  domain_name_configuration {
    certificate_arn = var.certificate_arn
    endpoint_type   = "REGIONAL"
    security_policy = "TLS_1_2"
  }
}

# API Mapping
resource "aws_apigatewayv2_api_mapping" "api" {
  api_id      = aws_apigatewayv2_api.nomad.id
  domain_name = aws_apigatewayv2_domain_name.api.id
  stage       = aws_apigatewayv2_stage.nomad.id
}

# Route53 Record for API Gateway
resource "aws_route53_record" "api" {
  zone_id = var.public_zone_id
  name    = var.api_domain
  type    = "A"

  alias {
    name                   = aws_apigatewayv2_domain_name.api.domain_name_configuration[0].target_domain_name
    zone_id                = aws_apigatewayv2_domain_name.api.domain_name_configuration[0].hosted_zone_id
    evaluate_target_health = false
  }
}

# API Gateway Routes for OIDC endpoints
resource "aws_apigatewayv2_route" "jwks" {
  api_id    = aws_apigatewayv2_api.nomad.id
  route_key = "GET /.well-known/jwks.json"
  target    = "integrations/${aws_apigatewayv2_integration.jwks.id}"
}

resource "aws_apigatewayv2_route" "oidc_config" {
  api_id    = aws_apigatewayv2_api.nomad.id
  route_key = "GET /.well-known/openid-configuration"
  target    = "integrations/${aws_apigatewayv2_integration.oidc_config.id}"
}

# API Gateway Integrations
resource "aws_apigatewayv2_integration" "jwks" {
  api_id             = aws_apigatewayv2_api.nomad.id
  integration_type   = "HTTP_PROXY"
  integration_uri    = var.nomad_alb_listener_arn
  integration_method = "GET"
  connection_type    = "VPC_LINK"
  connection_id      = aws_apigatewayv2_vpc_link.nomad.id
}

resource "aws_apigatewayv2_integration" "oidc_config" {
  api_id             = aws_apigatewayv2_api.nomad.id
  integration_type   = "HTTP_PROXY"
  integration_uri    = var.nomad_alb_listener_arn
  integration_method = "GET"
  connection_type    = "VPC_LINK"
  connection_id      = aws_apigatewayv2_vpc_link.nomad.id
}
/*
# WAF Web ACL - Always enabled
resource "aws_wafv2_web_acl" "api_gateway" {
  name        = "nomad-api-waf"
  description = "WAF for Nomad API Gateway"
  scope       = "REGIONAL"

  default_action {
    allow {}
  }

  # AWS Managed Rules - Common Rule Set
  rule {
    name     = "AWS-AWSManagedRulesCommonRuleSet"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWS-AWSManagedRulesCommonRuleSet"
      sampled_requests_enabled   = true
    }
  }

  # AWS Managed Rules - Known Bad Inputs Rule Set
  rule {
    name     = "AWS-AWSManagedRulesKnownBadInputsRuleSet"
    priority = 2

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWS-AWSManagedRulesKnownBadInputsRuleSet"
      sampled_requests_enabled   = true
    }
  }

  # AWS Managed Rules - Linux OS Rule Set
  rule {
    name     = "AWS-AWSManagedRulesLinuxRuleSet"
    priority = 3

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesLinuxRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWS-AWSManagedRulesLinuxRuleSet"
      sampled_requests_enabled   = true
    }
  }

  # Rate Limiting Rule
  rule {
    name     = "RateLimitRule"
    priority = 4

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = 100
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "RateLimitRule"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "nomad-api-waf"
    sampled_requests_enabled   = true
  }

  tags = {
    Name = "nomad-api-waf"
  }
}

# WAF Web ACL Association with API Gateway - Always enabled
resource "aws_wafv2_web_acl_association" "api_gateway" {
  resource_arn = "arn:aws:apigateway:${data.aws_region.current.name}::/apis/${aws_apigatewayv2_api.nomad.id}/stages/${aws_apigatewayv2_stage.nomad.name}"
  web_acl_arn  = aws_wafv2_web_acl.api_gateway.arn
}

# Get current AWS region
data "aws_region" "current" {}
*/