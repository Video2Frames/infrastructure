# Infraestrutura Video2Frames - Hackathon FIAP

## Introdução

Este repositório contém a infraestrutura como código (IaC) utilizando Terraform para provisionar os recursos necessários na AWS para o projeto Video2Frames, desenvolvido como parte do Hackathon da Pós-Graduação em Arquitetura de Software da FIAP. A solução provisiona uma arquitetura completa incluindo cluster Kubernetes (EKS), banco de dados PostgreSQL (RDS), buckets S3 para armazenamento de vídeos e frames extraídos, API Gateway para exposição de serviços, filas SQS e tópicos SNS para processamento assíncrono, além de uma função Lambda para inicialização do banco de dados, tudo integrado em uma VPC dedicada com subnets públicas e privadas.

## C4 Model

### Contexto

![img.jpg](docs/c4/images/1-contexto.png)

### Container

![img.jpg](docs/c4/images/2-container-1.png)
![img.jpg](docs/c4/images/2-container-2.png)
![img.jpg](docs/c4/images/2-container-3.png)
![img.jpg](docs/c4/images/2-container-4.png)
![img.jpg](docs/c4/images/2-container-5.png)
![img.jpg](docs/c4/images/2-container-6.png)

### Componentes

#### Video Processor

![img.jpg](docs/c4/images/3-component-processor-1.png)
![img.jpg](docs/c4/images/3-component-processor-2.png)
![img.jpg](docs/c4/images/3-component-processor-3.png)
![img.jpg](docs/c4/images/3-component-processor-4.png)