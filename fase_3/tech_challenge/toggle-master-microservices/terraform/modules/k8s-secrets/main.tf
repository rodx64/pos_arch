resource "kubernetes_secret_v1" "analytics" {
  metadata {
    name      = "analytics-secret"
    namespace = var.namespace
  }
  data = {
    AWS_DYNAMODB_TABLE = var.dynamodb_table_name
    AWS_SQS_URL        = var.sqs_queue_url
  }
  depends_on = [kubernetes_namespace_v1.this]
}

resource "kubernetes_secret_v1" "auth" {
  metadata {
    name      = "auth-secret"
    namespace = var.namespace
  }
  data = {
    DATABASE_URL = "postgresql://postgres:${local.auth_db_password}@${var.auth_db_endpoint}/auth_db"
    MASTER_KEY   = var.auth_master_key
  }
  depends_on = [kubernetes_namespace_v1.this]
}

resource "kubernetes_secret_v1" "flag" {
  metadata {
    name      = "flag-secret"
    namespace = var.namespace
  }
  data = {
    DATABASE_URL = "postgresql://postgres:${local.flag_db_password}@${var.flag_db_endpoint}/flag_db"
  }
  depends_on = [kubernetes_namespace_v1.this]
}

resource "kubernetes_secret_v1" "targeting" {
  metadata {
    name      = "targeting-secret"
    namespace = var.namespace
  }
  data = {
    DATABASE_URL = "postgresql://postgres:${local.analytics_db_password}@${var.analytics_db_endpoint}/analytics_db"
  }
  depends_on = [kubernetes_namespace_v1.this]
}

resource "kubernetes_secret_v1" "evaluation" {
  metadata {
    name      = "evaluation-secret"
    namespace = var.namespace
  }
  data = {
    SERVICE_API_KEY = var.evaluation_api_key
  }
  depends_on = [kubernetes_namespace_v1.this]
}

resource "kubernetes_namespace_v1" "this" {
  metadata {
    name = var.namespace
  }
}
