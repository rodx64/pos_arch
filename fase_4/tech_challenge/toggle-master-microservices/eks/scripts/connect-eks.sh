#!/bin/bash

set -e

# ==============================================================
# connect-eks.sh
# Abre tunnel SSH (Bastion/DBs) e Port-Forwards (Prometheus/Argo/Grafana)
# Uso: ./connect-eks.sh [start|stop|status]
# ==============================================================

BASTION_USER="ubuntu"
KEY_PATH="./iac-key.pem"
LOCAL_PORT="6443"
PROM_PORT="9090"
ARGO_PORT="8080"
GRAFANA_PORT="3000"
TUNNEL_PID_FILE="/tmp/eks-tunnel.pid"
PROM_PID_FILE="/tmp/eks-prometheus.pid"
ARGO_PID_FILE="/tmp/eks-argocd.pid"
GRAFANA_PID_FILE="/tmp/eks-grafana.pid"
PID_FILE_DB="/tmp/eks-db-tunnels.pid"

PROJECT_NAME="toggle-master"
BASTION_TAG="${PROJECT_NAME}-dev-bastion"
EKS_CLUSTER="${PROJECT_NAME}-eks"
AWS_REGION="${AWS_REGION:-us-east-1}"

# --------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

source ./env.sh

log()    { echo -e "${GREEN}[+]${NC} $1"; }
warn()   { echo -e "${YELLOW}[!]${NC} $1"; }
error()  { echo -e "${RED}[x]${NC} $1"; exit 1; }

# --------------------------------------------------------------
check_deps() {
  for cmd in aws ssh kubectl k9s; do
    if ! command -v "$cmd" &>/dev/null; then
      warn "Dependência não encontrada: $cmd"
      [ "$cmd" = "k9s" ] && warn "Instale k9s: https://k9scli.io/topics/install/"
      [ "$cmd" = "kubectl" ] && warn "Instale kubectl: https://kubernetes.io/docs/tasks/tools/"
      [ "$cmd" != "k9s" ] && [ "$cmd" != "kubectl" ] && error "$cmd é obrigatório"
    fi
  done
}

get_bastion_ip() {
  log "Buscando IP do bastion..."
  BASTION_IP=$(aws ec2 describe-instances \
    --region "$AWS_REGION" \
    --filters \
      "Name=tag:Name,Values=${BASTION_TAG}" \
      "Name=instance-state-name,Values=running" \
    --query 'Reservations[0].Instances[0].PublicIpAddress' \
    --output text)

  if [ -z "$BASTION_IP" ] || [ "$BASTION_IP" = "None" ]; then
    error "Bastion não encontrado. Verifique se a infra está provisionada."
  fi
  log "Bastion IP: ${BASTION_IP}"
}

get_eks_endpoint() {
  log "Buscando endpoint do EKS..."
  EKS_ENDPOINT=$(aws eks describe-cluster \
    --region "$AWS_REGION" \
    --name "$EKS_CLUSTER" \
    --query 'cluster.endpoint' \
    --output text | sed 's|https://||')

  if [ -z "$EKS_ENDPOINT" ] || [ "$EKS_ENDPOINT" = "None" ]; then
    error "Cluster EKS '${EKS_CLUSTER}' não encontrado."
  fi
  log "EKS endpoint: ${EKS_ENDPOINT}"
}

start_tunnel() {
  for f in "$TUNNEL_PID_FILE" "$PID_FILE_DB" "$PROM_PID_FILE" "$ARGO_PID_FILE" "$GRAFANA_PID_FILE"; do
    if [ -f "$f" ]; then
      OLD_PID=$(cat "$f")
      if kill -0 "$OLD_PID" 2>/dev/null; then
        error "Um dos túneis já está ativo (PID: $OLD_PID). Rode './connect-eks.sh stop' primeiro."
      fi
      rm -f "$f"
    fi
  done

  if [ ! -f "$KEY_PATH" ]; then
    error "Chave SSH não encontrada em: ${KEY_PATH}"
  fi
  chmod 400 "$KEY_PATH"

  log "Abrindo Túneis SSH via Bastion..."

  ssh -i "$KEY_PATH" \
    -o StrictHostKeyChecking=no \
    -o ServerAliveInterval=60 \
    -o ExitOnForwardFailure=yes \
    -L "${LOCAL_PORT}:${EKS_ENDPOINT}:443" \
    -L "${POSTGRES_LOCAL_AUTH_PORT}:${POSTGRES_AUTH_HOST}:${POSTGRES_PORT}" \
    -L "${POSTGRES_LOCAL_FLAG_PORT}:${POSTGRES_FLAG_HOST}:${POSTGRES_PORT}" \
    -L "${POSTGRES_LOCAL_TARG_PORT}:${POSTGRES_TARG_HOST}:${POSTGRES_PORT}" \
    "${BASTION_USER}@${BASTION_IP}" \
    -N -f

  TUNNEL_PID=$(pgrep -f "L ${LOCAL_PORT}:${EKS_ENDPOINT}:443" | head -1)
  echo "$TUNNEL_PID" > "$TUNNEL_PID_FILE"
  log "Túneis SSH/DB ativos (PID: ${TUNNEL_PID})"

  log "Abrindo port-forward para Prometheus (monitoring)..."
  kubectl port-forward svc/prometheus ${PROM_PORT}:9090 -n monitoring > /dev/null 2>&1 &
  echo $! > "$PROM_PID_FILE"

  log "Abrindo port-forward para Argo CD (argocd)..."
  kubectl port-forward svc/argocd-server ${ARGO_PORT}:80 -n argocd > /dev/null 2>&1 &
  echo $! > "$ARGO_PID_FILE"

  log "Abrindo port-forward para Grafana (monitoring)..."
  kubectl port-forward svc/grafana ${GRAFANA_PORT}:3000 -n monitoring > /dev/null 2>&1 &
  echo $! > "$GRAFANA_PID_FILE"
}

configure_kubectl() {
  log "Configurando kubectl..."
  aws eks update-kubeconfig --region "$AWS_REGION" --name "$EKS_CLUSTER"
  CLUSTER_ARN="arn:aws:eks:${AWS_REGION}:$(aws sts get-caller-identity --query Account --output text):cluster/${EKS_CLUSTER}"
  kubectl config set-cluster "$CLUSTER_ARN" --server="https://127.0.0.1:${LOCAL_PORT}" --insecure-skip-tls-verify=true
  kubectl config use-context "$CLUSTER_ARN"
}

verify_connection() {
  log "Verificando conexões..."
  sleep 5
  if kubectl get nodes &>/dev/null; then
    log "Conexão EKS:  OK"
    log "Prometheus:   http://localhost:${PROM_PORT}"
    log "Argo CD:      http://localhost:${ARGO_PORT}"
    log "Grafana:      http://localhost:${GRAFANA_PORT}/grafana" 
  else
    error "Falha ao conectar no cluster."
  fi
}

cmd_start() {
  check_deps
  get_bastion_ip
  get_eks_endpoint
  start_tunnel
  configure_kubectl
  verify_connection
}

cmd_stop() {
  for f in "$TUNNEL_PID_FILE" "$PROM_PID_FILE" "$ARGO_PID_FILE" "$GRAFANA_PID_FILE"; do
    if [ -f "$f" ]; then
      PID=$(cat "$f")
      kill "$PID" 2>/dev/null && log "Encerrado processo PID: $PID"
      rm -f "$f"
    fi
  done
  pkill -f "L ${LOCAL_PORT}:" 2>/dev/null || true
  pkill -f "port-forward" 2>/dev/null || true
  log "Todos os túneis encerrados."
}

cmd_status() {
  [ -f "$TUNNEL_PID_FILE" ] && log "SSH/EKS:    Ativo" || warn "SSH/EKS:    Inativo"
  [ -f "$PROM_PID_FILE" ]   && log "Prometheus: Ativo" || warn "Prometheus: Inativo"
  [ -f "$ARGO_PID_FILE" ]   && log "Argo CD:    Ativo" || warn "Argo CD:    Inativo"
  [ -f "$GRAFANA_PID_FILE" ] && log "Grafana:    Ativo" || warn "Grafana:    Inativo"
}

case "${1:-start}" in
  start)  cmd_start  ;;
  stop)   cmd_stop   ;;
  status) cmd_status ;;
  *) echo "Uso: $0 [start|stop|status]"; exit 1 ;;
esac
