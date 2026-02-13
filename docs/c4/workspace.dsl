workspace "Name" "Description" {

    !identifiers hierarchical

    model {
        u = person "Usuário" "Usuário que envia vídeos para extração de frames"
        email_service = softwareSystem "Serviço de Envio de Emails" "Serviço externo de envio de emails (SMTP/SendGrid/SES)" {
            tags "External"
        }
        ss = softwareSystem "Video2Frame" "Serviço de upload e processamento de vídeos para extração de frames" {
            identification = container "Identificação" "Cadastra e autentica usuários"
            uploader = container "Uploader" "Recebe vídeos enviados pelos usuários"
            processor = container "Processador" "Extrai frames e processa o vídeo" {
                videoUploadedListener = component "Video Uploaded Listener" {
                    description "Consome eventos VideoUploaded da Processing Queue e dispara processamento"
                    technology "Python + Boto3 SQS"
                    tags "InboundAdapter"
                }
                processVideoUseCase = component "Process Video Use Case" {
                    description "Orquestra o fluxo completo de processamento de vídeo"
                    technology "Python Application Service"
                    tags "Application"
                }
                eventPublisher = component "Event Publisher" {
                    description "Publica eventos de ciclo de vida do vídeo no tópico SNS"
                    technology "Python + Boto3 SNS"
                    tags "OutboundAdapter"
                }
                inputStorage = component "Input Storage" {
                    description "Realiza download de vídeos do bucket de upload"
                    technology "Python + Boto3 S3"
                    tags "OutboundAdapter"
                }
                outputStorage = component "Output Storage" {
                    description "Realiza upload de ZIPs com frames para bucket de saída"
                    technology "Python + Boto3 S3"
                    tags "OutboundAdapter"
                }
                videoMetadataReader = component "Video Metadata Reader" {
                    description "Extrai metadados do vídeo (duração, fps, etc)"
                    technology "Python + OpenCV"
                    tags "OutboundAdapter"
                }
                videoValidator = component "Video Validator" {
                    description "Valida metadados do vídeo"
                    technology "Python"
                    tags "OutboundAdapter"
                }
                frameSelector = component "Frame Selector" {
                    description "Seleciona os índices referentes aos frames a serem extraídos"
                    technology "Python (seleção uniforme por porcentagem configurável)"
                    tags "OutboundAdapter"
                }
                frameExtractor = component "Frame Extractor" {
                    description "Extrai frames do vídeo em formato de imagem"
                    technology "Python + OpenCV"
                    tags "OutboundAdapter"
                }
                framePackager = component "Frame Packager" {
                    description "Empacota frames extraídos em arquivo ZIP"
                    technology "Python + zipfile"
                    tags "OutboundAdapter"
                }
                tempFileManager = component "Temp File Manager" {
                    description "Gerencia criação e exclusão de arquivos temporários durante processamento"
                    technology "Python + tempfile"
                    tags "OutboundAdapter"
                }
            }
            notificator = container "Notificador" "Envia email de notificação de processamento ao usuário"
            status = container "Controle de Status" "Gerencia status e download de processamentos"
            identification_db = container "Database de Identificação" "Armazena dados de usuários" {
                tags "Database"
                technology  "PostgreSQL RDS"
            }
            status_db = container "Database de Processamento" "Armazena dados de processamento" {
                tags "Database"
                technology  "AWS PostgreSQL RDS"
            }
            upload_storage = container "Storage de Upload" "Armazena vídeos enviados" {
                tags "Storage"
                technology  "AWS S3"
            }
            output_storage = container "Storage de Processamento" "Armazena ZIPs com frames processados" {
                tags "Storage"
                technology  "AWS S3"
            }
            video_events_topic = container "Tópico de Eventos de Vídeo" "Tópico central para eventos de ciclo de vida do vídeo" {
                tags "Queue"
                technology  "AWS SNS"
            }
            status_updates_queue = container "Fila de Atualizações de Status" "Fila para rastreamento de mudanças de status" {
                tags "Queue"
                technology  "AWS SQS FIFO"
            }
            processing_queue = container "Fila de Processamento" "Fila para processamento assíncrono de vídeos" {
                tags "Queue"
                technology  "AWS SQS Standard"
            }
            notifications_queue = container "Fila de Notificações" "Fila para envio de notificações" {
                tags "Queue"
                technology  "AWS SQS Standard"
            }
            processing_dlq = container "DLQ Processamento" "Dead letter queue para mensagens de processamento que falharam após múltiplas tentativas" {
                tags "Queue" "DLQ"
                technology  "AWS SQS Standard"
            }
            status_updates_dlq = container "DLQ Atualizações de Status" "Dead letter queue para mensagens de atualização de status que falharam após múltiplas tentativas" {
                tags "Queue" "DLQ"
                technology  "AWS SQS FIFO"
            }
            notifications_dlq = container "DLQ Notificações" "Dead letter queue para mensagens de notificação que falharam após múltiplas tentativas" {
                tags "Queue" "DLQ"
                technology  "AWS SQS Standard"
            }
            apigateway = container "API Gateway" "Ponto de entrada único para roteamento de requisições HTTP" {
                technology  "AWS API Gateway"
            }
        }

        u -> ss.apigateway "Usa"
        email_service -> u "Envia emails de notificação"
        ss.apigateway -> ss.identification "Roteia requisições de autenticação e cadastro"
        ss.apigateway -> ss.uploader "Roteia requisições de upload de vídeos"
        ss.apigateway -> ss.status "Roteia requisições de consulta de status e download"
        ss.identification -> ss.identification_db "Cadastra usuários e Valida credenciais"
        ss.uploader -> ss.identification "Valida token de autenticação"
        ss.uploader -> ss.upload_storage "Escreve"
        ss.uploader -> ss.video_events_topic "Publica evento VideoUploaded"
        ss.processor -> ss.upload_storage "Lê"
        ss.processor -> ss.video_events_topic "Publica eventos VideoProcessing e VideoProcessed"
        ss.video_events_topic -> ss.status_updates_queue "Roteia VideoUploaded, VideoProcessing, VideoProcessed"
        ss.video_events_topic -> ss.processing_queue "Roteia VideoUploaded"
        ss.video_events_topic -> ss.notifications_queue "Roteia VideoProcessed"
        ss.status_updates_queue -> ss.status "Consome eventos para atualizar status"
        ss.processing_queue -> ss.processor "Consome eventos para processar vídeo"
        ss.status -> ss.identification "Valida token de autenticação"
        ss.status -> ss.output_storage "Lê"
        ss.processor -> ss.output_storage "Escreve"
        ss.notifications_queue -> ss.notificator "Consome eventos para notificar"
        ss.notificator -> email_service "Envia emails de notificação"
        ss.status -> ss.status_db "Lê e escreve"
        ss.processing_queue -> ss.processing_dlq "Move mensagens após exceder limite de tentativas"
        ss.status_updates_queue -> ss.status_updates_dlq "Move mensagens após exceder limite de tentativas"
        ss.notifications_queue -> ss.notifications_dlq "Move mensagens após exceder limite de tentativas"
        
        // Relacionamentos dos componentes do Processor
        ss.processing_queue -> ss.processor.videoUploadedListener "Entrega mensagens VideoUploaded"
        ss.processor.videoUploadedListener -> ss.processor.processVideoUseCase "Dispara processamento"
        ss.processor.processVideoUseCase -> ss.processor.inputStorage "Solicita download do vídeo"
        ss.processor.processVideoUseCase -> ss.processor.tempFileManager "Gerencia arquivos temporários"
        ss.processor.processVideoUseCase -> ss.processor.videoMetadataReader "Solicita leitura de metadados"
        ss.processor.processVideoUseCase -> ss.processor.videoValidator "Solicita validação do vídeo"
        ss.processor.processVideoUseCase -> ss.processor.frameSelector "Solicita seleção de frames"
        ss.processor.processVideoUseCase -> ss.processor.frameExtractor "Solicita extração de frames"
        ss.processor.processVideoUseCase -> ss.processor.framePackager "Solicita empacotamento de frames"
        ss.processor.processVideoUseCase -> ss.processor.outputStorage "Solicita upload do ZIP"
        ss.processor.processVideoUseCase -> ss.processor.eventPublisher "Publica eventos de status"
        ss.processor.inputStorage -> ss.upload_storage "Realiza download de vídeos"
        ss.processor.outputStorage -> ss.output_storage "Realiza upload de ZIPs"
        ss.processor.eventPublisher -> ss.video_events_topic "Publica eventos VideoProcessing e VideoProcessed"
    }

    views {
        systemContext ss "Contexto" {
            include u
            include ss
            include email_service
        }

        container ss "1_autenticacao_cadastro" {
            include u
            include ss.apigateway
            include ss.identification
            include ss.identification_db
            autolayout lr
        }

        container ss "2_upload_video" {
            include u
            include ss.apigateway
            include ss.uploader
            include ss.identification
            include ss.upload_storage
            include ss.video_events_topic
            autolayout lr
        }

        container ss "3_processamento_video" {
            include ss.processor
            include ss.upload_storage
            include ss.video_events_topic
            include ss.processing_queue
            include ss.output_storage
            include ss.processing_dlq
            autolayout lr
        }

        container ss "4_status_download" {
            include u
            include ss.apigateway
            include ss.status
            include ss.status_db
            include ss.output_storage
            include ss.identification
            include ss.status_updates_queue
            include ss.status_updates_dlq
            autolayout lr
        }

        container ss "5_notificacoes" {
            include ss.notificator
            include ss.notifications_queue
            include ss.notifications_dlq
            include email_service
            include u
            autolayout lr
        }

        container ss "6_eventos_filas_infraestrutura" {
            include ss.video_events_topic
            include ss.processing_queue
            include ss.status_updates_queue
            include ss.notifications_queue
            include ss.processing_dlq
            include ss.status_updates_dlq
            include ss.notifications_dlq
            autolayout lr
        }
        
        component ss.processor "7a_processor_fluxo_principal" {
            include ss.processing_queue
            include ss.processor.videoUploadedListener
            include ss.processor.processVideoUseCase
            include ss.processor.inputStorage
            include ss.processor.outputStorage
            include ss.processor.eventPublisher
            include ss.upload_storage
            include ss.output_storage
            include ss.video_events_topic
            autolayout lr
        }
        
        component ss.processor "7b_processor_analise_validacao" {
            include ss.processor.processVideoUseCase
            include ss.processor.videoMetadataReader
            include ss.processor.videoValidator
            include ss.processor.frameSelector
            autolayout lr
        }
        
        component ss.processor "7c_processor_extracao_empacotamento" {
            include ss.processor.processVideoUseCase
            include ss.processor.frameExtractor
            include ss.processor.framePackager
            include ss.processor.tempFileManager
            autolayout lr
        }
        
        component ss.processor "7d_processor_storage_eventos" {
            include ss.processor.processVideoUseCase
            include ss.processor.inputStorage
            include ss.processor.outputStorage
            include ss.processor.eventPublisher
            include ss.processor.tempFileManager
            include ss.upload_storage
            include ss.output_storage
            include ss.video_events_topic
            autolayout lr
        }

        styles {
            element "Element" {
                color #0773af
                stroke #0773af
                strokeWidth 7
                shape roundedbox
            }
            element "Person" {
                shape person
            }
            element "Database" {
                shape cylinder
            }
            element "Queue" {
                shape pipe
            }
            element "DLQ" {
                background #ff6b6b
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "InboundAdapter" {
                background #90ee90
                color #000000
            }
            element "ApplicationCore" {
                background #ff8c00
                color #ffffff
            }
            element "OutboundAdapter" {
                background #87ceeb
                color #000000
            }
            element "Boundary" {
                strokeWidth 5
            }
            relationship "Relationship" {
                fontSize 24
            }
        }
    }

    configuration {
        scope softwaresystem
    }

}