variable "queue_name" {
  type = string
}

variable "visibility_timeout_seconds" {
  type    = number
  default = 30
}

variable "message_retention_seconds" {
  type    = number
  default = 86400
}

variable "delay_seconds" {
  type    = number
  default = 0
}

variable "receive_wait_time_seconds" {
  type    = number
  default = 0
}

variable "create_dlq" {
  type    = bool
  default = true
}

variable "max_receive_count" {
  type    = number
  default = 3
}
