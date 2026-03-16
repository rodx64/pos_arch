#!/bin/bash

set -e

# ==============================================================
# connect-eks.sh
# Abre tunnel SSH pelo bastion e configura kubectl/k9s local
# Uso: ./connect-eks.sh [start|stop|status]
# ==============================================================

BASTION_USER="ubuntu"
KEY_PATH="./iac-key.pem"
LOCAL_PORT="6443"
TUNNEL_PID_FILE="/tmp/eks-tunnel.pid"
PROJECT_NAME="toggle-master"
BASTION_TAG="${PROJECT_NAME}-dev-bastion"
EKS_CLUSTER="${PROJECT_NAME}-eks"
AWS_REGION="${AWS_REGION:-us-east-1}"

# --------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

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
  if [ -f "$TUNNEL_PID_FILE" ]; then
    OLD_PID=$(cat "$TUNNEL_PID_FILE")
    if kill -0 "$OLD_PID" 2>/dev/null; then
      warn "Tunnel já está ativo (PID: ${OLD_PID}). Use './connect-eks.sh stop' para encerrar."
      return
    else
      rm -f "$TUNNEL_PID_FILE"
    fi
  fi

  if [ ! -f "$KEY_PATH" ]; then
    error "Chave SSH não encontrada em: ${KEY_PATH}"
  fi

  chmod 400 "$KEY_PATH"

  log "Abrindo tunnel SSH: localhost:${LOCAL_PORT} → ${EKS_ENDPOINT}:443"
  ssh -i "$KEY_PATH" \
    -o StrictHostKeyChecking=no \
    -o ServerAliveInterval=60 \
    -o ServerAliveCountMax=3 \
    -o ExitOnForwardFailure=yes \
    -L "${LOCAL_PORT}:${EKS_ENDPOINT}:443" \
    "${BASTION_USER}@${BASTION_IP}" \
    -N -f

  # Captura o PID do tunnel
  TUNNEL_PID=$(pgrep -f "L ${LOCAL_PORT}:${EKS_ENDPOINT}:443" | head -1)
  echo "$TUNNEL_PID" > "$TUNNEL_PID_FILE"
  log "Tunnel ativo (PID: ${TUNNEL_PID})"
}

configure_kubectl() {
  log "Configurando kubectl..."
  aws eks update-kubeconfig \
    --region "$AWS_REGION" \
    --name "$EKS_CLUSTER"

  CLUSTER_ARN="arn:aws:eks:${AWS_REGION}:$(aws sts get-caller-identity --query Account --output text):cluster/${EKS_CLUSTER}"

  kubectl config set-cluster "$CLUSTER_ARN" \
    --server="https://127.0.0.1:${LOCAL_PORT}" \
    --insecure-skip-tls-verify=true

  kubectl config use-context "$CLUSTER_ARN"

  log "kubectl configurado para cluster: ${CLUSTER_ARN}"
}

verify_connection() {
  log "Verificando conexão com o cluster..."
  sleep 3

  if kubectl get nodes &>/dev/null; then
    log "Conexão estabelecida com sucesso!"
    echo ""
    kubectl get nodes
  else
    error "Falha ao conectar no cluster. Verifique o tunnel e as credenciais AWS."
  fi
}

cmd_start() {
  check_deps
  get_bastion_ip
  get_eks_endpoint
  start_tunnel
  configure_kubectl
  verify_connection
  echo ""
  log "Pronto! Execute 'k9s' para abrir o painel."
  log "Para encerrar o tunnel: ./connect-eks.sh stop"
}

cmd_stop() {
  if [ -f "$TUNNEL_PID_FILE" ]; then
    PID=$(cat "$TUNNEL_PID_FILE")
    if kill -0 "$PID" 2>/dev/null; then
      kill "$PID"
      rm -f "$TUNNEL_PID_FILE"
      log "Tunnel encerrado (PID: ${PID})"
    else
      warn "Tunnel não estava ativo."
      rm -f "$TUNNEL_PID_FILE"
    fi
  else
    warn "Nenhum tunnel registrado. Verificando por processos SSH ativos..."
    pkill -f "L ${LOCAL_PORT}:" 2>/dev/null && log "Processos SSH encerrados." || warn "Nenhum processo encontrado."
  fi
}

cmd_status() {
  if [ -f "$TUNNEL_PID_FILE" ]; then
    PID=$(cat "$TUNNEL_PID_FILE")
    if kill -0 "$PID" 2>/dev/null; then
      log "Tunnel ativo (PID: ${PID}) em localhost:${LOCAL_PORT}"
      echo ""
      kubectl get nodes 2>/dev/null || warn "kubectl não conseguiu conectar — tunnel pode estar instável."
    else
      warn "PID file existe mas processo não está rodando."
      rm -f "$TUNNEL_PID_FILE"
    fi
  else
    warn "Nenhum tunnel ativo."
  fi
}

# --------------------------------------------------------------
case "${1:-start}" in
  start)  cmd_start  ;;
  stop)   cmd_stop   ;;
  status) cmd_status ;;
  *)
    echo "Uso: $0 [start|stop|status]"
    echo ""
    echo "  start   Abre tunnel SSH e configura kubectl (padrão)"
    echo "  stop    Encerra o tunnel"
    echo "  status  Verifica se o tunnel está ativo"
    exit 1
    ;;
esac
