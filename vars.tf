variable "region" {
  default     = "us-east-1"
  description = "A região na AWS onde os recursos serão criados"
}

variable "db_user" {
  description = "O usuário master do banco de dados"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "A senha master do banco de dados"
  type        = string
  sensitive   = true
}

variable "tags" {
  default = {
    Environment = "PRD"
    Project     = "hackathon-infra"
  }
  description = "Tags padrão para todos os recursos"
}
