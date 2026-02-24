#!/usr/bin/env python3
"""
🤖 Orquestrador de Resposta a Incidentes

Este script:
1. Lê um alerta (JSON)
2. Usa IA para classificar o tipo de incidente
3. Seleciona e executa o runbook apropriado
4. Registra o resultado

Uso:
    python incident_handler.py alerts/high_memory.json
    python incident_handler.py alerts/database_down.json
    python incident_handler.py alerts/high_cpu.json
"""
import json
import sys
import requests
from pathlib import Path
from datetime import datetime
from importlib import import_module


# Mapeamento: tipo de incidente → runbook
RUNBOOK_MAP = {
    "memory": "runbooks.clear_memory",
    "database": "runbooks.restart_service",
    "cpu": "runbooks.scale_resources",
    "service": "runbooks.restart_service"
}


def load_alert(alert_file: str) -> dict:
    """
    Carrega o alerta de um arquivo JSON.
    """
    path = Path(alert_file)
    if not path.exists():
        print(f"❌ Arquivo não encontrado: {alert_file}")
        sys.exit(1)
    
    with open(path) as f:
        return json.load(f)


def classify_with_ollama(alert: dict) -> str:
    """
    Usa Ollama para classificar o tipo de incidente.
    """
    prompt = f"""Classifique este alerta em UMA das categorias:
- memory (problemas de memória)
- database (problemas de banco de dados)
- cpu (problemas de CPU)
- service (serviço fora do ar)

Alerta:
{json.dumps(alert, indent=2)}

Responda APENAS com a categoria, uma única palavra."""

    try:
        response = requests.post(
            "http://localhost:11434/api/generate",
            json={
                "model": "llama3.2",
                "prompt": prompt,
                "stream": False
            },
            timeout=30
        )
        
        category = response.json()["response"].strip().lower()
        
        # Limpar resposta (pegar só a primeira palavra)
        category = category.split()[0].strip('.,!?')
        
        # Validar categoria
        if category not in RUNBOOK_MAP:
            # Fallback: tentar detectar pelo conteúdo do alerta
            alert_type = alert.get("type", "").lower()
            if "memory" in alert_type:
                return "memory"
            elif "database" in alert_type or "connection" in alert_type:
                return "database"
            elif "cpu" in alert_type:
                return "cpu"
            return "service"
        
        return category
        
    except requests.exceptions.ConnectionError:
        print("⚠️  Ollama não disponível, usando classificação por regras...")
        # Fallback sem IA
        alert_type = alert.get("type", "").lower()
        if "memory" in alert_type:
            return "memory"
        elif "database" in alert_type or "connection" in alert_type:
            return "database"
        elif "cpu" in alert_type:
            return "cpu"
        return "service"


def execute_runbook(incident_type: str, alert: dict) -> dict:
    """
    Importa e executa o runbook apropriado.
    """
    runbook_module = RUNBOOK_MAP.get(incident_type)
    
    if not runbook_module:
        print(f"❌ Nenhum runbook para: {incident_type}")
        return {"status": "error", "message": "No runbook available"}
    
    try:
        # Importar o módulo do runbook
        module = import_module(runbook_module)
        
        # Executar
        result = module.execute(alert)
        return result
        
    except Exception as e:
        print(f"❌ Erro ao executar runbook: {e}")
        return {"status": "error", "message": str(e)}


def save_incident_log(alert: dict, incident_type: str, result: dict):
    """
    Salva log do incidente para histórico.
    """
    log_entry = {
        "timestamp": datetime.now().isoformat(),
        "alert_id": alert.get("alert_id"),
        "incident_type": incident_type,
        "runbook_executed": result.get("runbook"),
        "status": result.get("status"),
        "actions": result.get("actions_taken", [])
    }
    
    log_file = Path("logs/incidents.log")
    log_file.parent.mkdir(exist_ok=True)
    
    with open(log_file, "a") as f:
        f.write(json.dumps(log_entry) + "\n")
    
    print(f"\n📝 Log salvo em: {log_file}")


def main():
    print("\n" + "=" * 60)
    print("🤖 ORQUESTRADOR DE RESPOSTA A INCIDENTES")
    print("=" * 60)
    
    # 1. Verificar argumento
    if len(sys.argv) < 2:
        print("\n❌ Uso: python incident_handler.py <arquivo_alerta.json>")
        print("\nExemplos:")
        print("  python incident_handler.py alerts/high_memory.json")
        print("  python incident_handler.py alerts/database_down.json")
        print("  python incident_handler.py alerts/high_cpu.json")
        sys.exit(1)
    
    alert_file = sys.argv[1]
    
    # 2. Carregar alerta
    print(f"\n📂 Carregando alerta: {alert_file}")
    alert = load_alert(alert_file)
    
    print(f"\n🚨 ALERTA RECEBIDO:")
    print(f"   ID: {alert.get('alert_id')}")
    print(f"   Severidade: {alert.get('severity', 'unknown').upper()}")
    print(f"   Mensagem: {alert.get('message')}")
    
    # 3. Classificar com IA
    print("\n🤖 Classificando incidente com IA...")
    incident_type = classify_with_ollama(alert)
    print(f"   ✓ Tipo identificado: {incident_type.upper()}")
    
    # 4. Selecionar runbook
    runbook = RUNBOOK_MAP.get(incident_type, "unknown")
    print(f"   ✓ Runbook selecionado: {runbook}")
    
    # 5. Executar runbook
    print("\n⚡ Executando runbook...")
    result = execute_runbook(incident_type, alert)
    
    # 6. Salvar log
    save_incident_log(alert, incident_type, result)
    
    # 7. Resumo final
    print("\n" + "=" * 60)
    print("📊 RESUMO DA RESPOSTA")
    print("=" * 60)
    print(f"   Alerta: {alert.get('alert_id')}")
    print(f"   Tipo: {incident_type}")
    print(f"   Runbook: {result.get('runbook')}")
    print(f"   Status: {result.get('status', 'unknown').upper()}")
    print(f"   Duração: {result.get('duration_seconds', 0)}s")
    print("=" * 60)
    
    # Exit code baseado no resultado
    if result.get("status") == "success":
        print("\n✅ INCIDENTE RESOLVIDO AUTOMATICAMENTE!")
        sys.exit(0)
    else:
        print("\n❌ FALHA - Escalar para equipe de plantão")
        sys.exit(1)


if __name__ == "__main__":
    main()
