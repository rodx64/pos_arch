resource "aws_sqs_queue" "dlq" {
  count = var.create_dlq ? 1 : 0

  name                      = "${var.queue_name}-dlq"
  message_retention_seconds = 1209600 # 14 dias na DLQ

  tags = {
    Name    = "${var.queue_name}-dlq"
    Project = var.project_name
    Env     = var.env
  }
}

resource "aws_sqs_queue" "this" {
  name                       = var.queue_name
  visibility_timeout_seconds = var.visibility_timeout_seconds
  message_retention_seconds  = var.message_retention_seconds
  delay_seconds              = var.delay_seconds
  receive_wait_time_seconds  = var.receive_wait_time_seconds

  dynamic "redrive_policy" {
    for_each = var.create_dlq ? [1] : []
    content {
      dead_letter_target_arn = aws_sqs_queue.dlq[0].arn
      max_receive_count      = var.max_receive_count
    }
  }

  tags = {
    Name    = var.queue_name
    Project = var.project_name
    Env     = var.env
  }
}
