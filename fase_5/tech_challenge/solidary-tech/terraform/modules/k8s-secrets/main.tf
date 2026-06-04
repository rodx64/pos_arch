resource "kubernetes_namespace_v1" "this" {
  metadata {
    name = var.namespace
  }
}

resource "kubernetes_secret_v1" "donation" {
  metadata {
    name      = "donation-secret"
    namespace = var.namespace
  }
  data = {
    DATABASE_URL = "postgresql://postgres:${local.donation_db_password_encoded}@${var.donation_db_endpoint}/donation_db"
    AWS_SQS_URL  = var.sqs_queue_url
  }
  depends_on = [kubernetes_namespace_v1.this]
}

resource "kubernetes_secret_v1" "ngo" {
  metadata {
    name      = "ngo-secret"
    namespace = var.namespace
  }
  data = {
    DATABASE_URL = "postgresql://postgres:${local.ngo_db_password_encoded}@${var.ngo_db_endpoint}/ngo_db"
  }
  depends_on = [kubernetes_namespace_v1.this]
}

resource "kubernetes_secret_v1" "volunteer" {
  metadata {
    name      = "volunteer-secret"
    namespace = var.namespace
  }
  data = {
    AWS_DYNAMODB_TABLE = var.dynamodb_table_name
  }
  depends_on = [kubernetes_namespace_v1.this]
}
