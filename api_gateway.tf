resource "aws_apigatewayv2_api" "hackathon_api" {
  name          = "hackathon-api"
  protocol_type = "HTTP"
  tags          = var.tags
}

resource "aws_apigatewayv2_integration" "ingress_backend" {
  depends_on             = [helm_release.nginx_ingress]
  api_id                 = aws_apigatewayv2_api.hackathon_api.id
  integration_type       = "HTTP_PROXY"
  integration_uri        = "http://${data.kubernetes_service.nginx_ingress.status[0].load_balancer[0].ingress[0].hostname}"
  integration_method     = "ANY"
  payload_format_version = "1.0"
  request_parameters = {
    "overwrite:path" = "/video2frame/$${request.path.proxy}"
  }
}

resource "aws_apigatewayv2_route" "backend_routes" {
  api_id    = aws_apigatewayv2_api.hackathon_api.id
  route_key = "ANY /video2frame/{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.ingress_backend.id}"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.hackathon_api.id
  name        = "$default"
  auto_deploy = true
}
