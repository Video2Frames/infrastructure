output "cluster_name" {
  value       = module.eks.cluster_name
  description = "Nome do cluster EKS"
}

output "api_gateway_url" {
  value       = aws_apigatewayv2_api.hackathon_api.api_endpoint
  description = "URL do API Gateway"
}

output "api_gateway_id" {
  value       = aws_apigatewayv2_api.hackathon_api.id
  description = "ID do API Gateway"
}

output "eks_node_sg_id" {
  value       = module.eks.node_security_group_id
  description = "ID do security group dos nodes do EKS"
}

output "database_identifier" {
  value       = aws_db_instance.hackathon_psql_db.identifier
  description = "O ID da instância RDS"
}

output "database_uri" {
  value       = aws_db_instance.hackathon_psql_db.endpoint
  description = "O endpoint da instância RDS"
}

output "order_created_topic_arn" {
  value       = aws_sns_topic.video_events.arn
  description = "O ARN do tópico SNS de eventos de vídeo"
}
