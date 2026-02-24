#!/usr/bin/env python3
"""
📋 Runbook: Restart Service
Ação: Reinicia o serviço que está com problema

Em produção, isso executaria:
- kubectl rollout restart deployment/app
- systemctl restart app
- docker restart container_name
"""
import time
from datetime import datetime


def execute(alert: dict) -> dict:
    """
    Executa o runbook de restart.
    
    Args:
        alert: Dados do alerta
        
    Returns:
        Resultado da execução
    """
    print("\n" + "=" * 50)
    print("📋 RUNBOOK: Restart Service")
    print("=" * 50)
    
    service = alert.get("metrics", {}).get("database", "app-service")
    
    # Passo 1: Verificar status atual
    print("\n⏳ Passo 1: Verificando status atual...")
    time.sleep(1)
    print("   ✓ Serviço identificado: app-service")
    print("   ✓ Status: UNHEALTHY")
    
    # Passo 2: Parar serviço
    print("\n⏳ Passo 2: Parando serviço...")
    time.sleep(1)
    print("   ✓ Enviando SIGTERM...")
    print("   ✓ Aguardando graceful shutdown...")
    print("   ✓ Serviço parado")
    
    # Passo 3: Limpar recursos
    print("\n⏳ Passo 3: Limpando recursos...")
    time.sleep(1)
    print("   ✓ Conexões de DB fechadas")
    print("   ✓ Cache limpo")
    
    # Passo 4: Reiniciar
    print("\n⏳ Passo 4: Reiniciando serviço...")
    time.sleep(1)
    print("   ✓ Iniciando novo processo...")
    print("   ✓ Health check: OK")
    print("   ✓ Serviço reiniciado com sucesso!")
    
    # Resultado
    result = {
        "runbook": "restart_service",
        "status": "success",
        "actions_taken": [
            "Stopped service gracefully",
            "Cleared connections",
            "Restarted service",
            "Verified health check"
        ],
        "duration_seconds": 4,
        "timestamp": datetime.now().isoformat()
    }
    
    print("\n" + "=" * 50)
    print("✅ RUNBOOK CONCLUÍDO COM SUCESSO")
    print("=" * 50)
    
    return result


if __name__ == "__main__":
    # Teste standalone
    test_alert = {"metrics": {"database": "postgres"}}
    execute(test_alert)
