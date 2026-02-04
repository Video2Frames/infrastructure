# SNS Topic
resource "aws_sns_topic" "video_events" {
  name                        = "video-events.fifo"
  fifo_topic                  = true
  content_based_deduplication = true
  tags                        = var.tags
}

# SQS Queues
resource "aws_sqs_queue" "status_updates_queue" {
  name                        = "status-updates.fifo"
  fifo_queue                  = true
  content_based_deduplication = true
  visibility_timeout_seconds  = 300    # 5 minutes
  message_retention_seconds   = 345600 # 4 days
  tags                        = var.tags
}

resource "aws_sqs_queue" "processing_queue" {
  name                        = "processing"
  fifo_queue                  = false
  content_based_deduplication = false  # only for FIFO queues
  visibility_timeout_seconds  = 900    # 15 minutes
  message_retention_seconds   = 345600 # 4 days
  tags                        = var.tags
}

resource "aws_sqs_queue" "notifications_queue" {
  name                        = "notifications"
  fifo_queue                  = false
  content_based_deduplication = false  # only for FIFO queues
  visibility_timeout_seconds  = 300    # 5 minutes
  message_retention_seconds   = 345600 # 4 days
  tags                        = var.tags
}

# SNS to SQS Subscriptions
resource "aws_sns_topic_subscription" "video_events_subscription_to_status_updates" {
  topic_arn = aws_sns_topic.video_events.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.status_updates_queue.arn
  filter_policy = jsonencode({
    event_type = [
      "video.uploaded",
      "video.processing_started",
      "video.processed",
      "video.processing_failed"
    ]
  })
  filter_policy_scope = "MessageAttributes"
}

resource "aws_sns_topic_subscription" "video_events_subscription_to_processing" {
  topic_arn = aws_sns_topic.video_events.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.processing_queue.arn
  filter_policy = jsonencode({
    event_type = [
      "video.uploaded"
    ]
  })
  filter_policy_scope = "MessageAttributes"
}

resource "aws_sns_topic_subscription" "video_events_subscription_to_notifications" {
  topic_arn = aws_sns_topic.video_events.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.notifications_queue.arn
  filter_policy = jsonencode({
    event_type = [
      "video.processed",
      "video.processing_failed"
    ]
  })
  filter_policy_scope = "MessageAttributes"
}

# SQS Queue Policy to allow SNS to send messages
resource "aws_sqs_queue_policy" "status_updates_policy" {
  queue_url = aws_sqs_queue.status_updates_queue.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "sns.amazonaws.com"
        }
        Action   = "sqs:SendMessage"
        Resource = aws_sqs_queue.status_updates_queue.arn
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = aws_sns_topic.video_events.arn
          }
        }
      }
    ]
  })
}

resource "aws_sqs_queue_policy" "processing_policy" {
  queue_url = aws_sqs_queue.processing_queue.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "sns.amazonaws.com"
        }
        Action   = "sqs:SendMessage"
        Resource = aws_sqs_queue.processing_queue.arn
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = aws_sns_topic.video_events.arn
          }
        }
      }
    ]
  })
}

resource "aws_sqs_queue_policy" "notifications_policy" {
  queue_url = aws_sqs_queue.notifications_queue.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "sns.amazonaws.com"
        }
        Action   = "sqs:SendMessage"
        Resource = aws_sqs_queue.notifications_queue.arn
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = aws_sns_topic.video_events.arn
          }
        }
      }
    ]
  })
}
