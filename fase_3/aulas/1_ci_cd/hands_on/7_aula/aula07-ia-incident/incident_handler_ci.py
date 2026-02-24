#!/usr/bin/env python3
"""
🤖 Orquestrador de Resposta a Incidentes (versão CI/CD)

Este script usa Google Gemini API para classificar incidentes no GitHub Actions.

Uso:
    export GEMINI_API_KEY="sua-chave"
    python incident_handler_ci.py alerts/high_memory.json

Obter chave grátis:
    - Gemini: https://aistudio.google.com/apikey
    - Groq (alternativa): https://console.groq.com
"""
import json
import sys
import os
import requests
from pathlib import Path
from datetime import datetime
from importlib import import_module


# ============================================================
# CONFIGURAÇÃO: Escolha qual API usar
# ============================================================
USE_GEMINI = True  # Mude para False para usar Groq


# Mapeamento: tipo de incidente → runbook
RUNBOOK_MAP = {
    "memory": "runbooks.clear_memory",
    "database": "runbooks.restart_service",
    "cpu": "runbooks.scale_resources",
    "service": "runbooks.restart_service"
}


def load_alert(alert_file: str) -> dict:
    """Carrega o alerta de um arquivo JSON."""
    path = Path(alert_file)
    if not path.exists():
        print(f"❌ Arquivo não encontrado: {alert_file}")
        sys.exit(1)
    
    with open(path) as f:
        return json.load(f)


def classify_with_gemini(alert: dict) -> str:
    """
    Usa Google Gemini API para classificar o tipo de incidente.
    """
    api_key = os.environ.get("GEMINI_API_KEY")
    
    if not api_key:
        print("❌ GEMINI_API_KEY não configurada!")
        print("")
        print("Para configurar:")
        print("  1. Acesse https://aistudio.google.com/apikey")
        print("  2. Clique em 'Create API Key'")
        print("  3. export GEMINI_API_KEY='sua-chave'")
        sys.exit(1)
    
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
            f"https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key={api_key}",
            headers={"Content-Type": "application/json"},
            json={
                "contents": [{
                    "parts": [{"text": prompt}]
                }],
                "generationConfig": {
                    "temperature": 0.1,
                    "maxOutputTokens": 10
                }
            },
            timeout=30
        )
        
        response.raise_for_status()
        category = response.json()["candidates"][0]["content"]["parts"][0]["text"].strip().lower()
        
        # Limpar e validar
        category = category.split()[0].strip('.,!?"')
        
        if category not in RUNBOOK_MAP:
            # Fallback por tipo do alerta
            alert_type = alert.get("type", "").lower()
            if "memory" in alert_type:
                return "memory"
            elif "database" in alert_type or "connection" in alert_type:
                return "database"
            elif "cpu" in alert_type:
                return "cpu"
            return "service"
        
        return category
        
    except requests.exceptions.HTTPError as e:
        print(f"❌ Erro na API Gemini: {e}")
        sys.exit(1)


# ============================================================
# ALTERNATIVA: Groq API (descomente para usar)
# ============================================================
# def classify_with_groq(alert: dict) -> str:
#     """
#     Usa Groq API para classificar o tipo de incidente.
#     """
#     api_key = os.environ.get("GROQ_API_KEY")
#     
#     if not api_key:
#         print("❌ GROQ_API_KEY não configurada!")
#         print("   export GROQ_API_KEY='sua-chave'")
#         sys.exit(1)
#     
#     try:
#         response = requests.post(
#             "https://api.groq.com/openai/v1/chat/completions",
#             headers={
#                 "Authorization": f"Bearer {api_key}",
#                 "Content-Type": "application/json"
#             },
#             json={
#                 "model": "llama-3.1-8b-instant",
#                 "messages": [
#                     {
#                         "role": "system",
#                         "content": "Classifique alertas em UMA categoria: memory, database, cpu, ou service. Responda APENAS com a categoria."
#                     },
#                     {
#                         "role": "user",
#                         "content": f"Alerta: {json.dumps(alert)}"
#                     }
#                 ],
#                 "temperature": 0.1,
#                 "max_tokens": 10
#             },
#             timeout=30
#         )
#         
#         response.raise_for_status()
#         category = response.json()["choices"][0]["message"]["content"].strip().lower()
#         category = category.split()[0].strip('.,!?"')
#         
#         if category not in RUNBOOK_MAP:
#             alert_type = alert.get("type", "").lower()
#             if "memory" in alert_type:
#                 return "memory"
#             elif "database" in alert_type or "connection" in alert_type:
#                 return "database"
#             elif "cpu" in alert_type:
#                 return "cpu"
#             return "service"
#         
#         return category
#         
#     except requests.exceptions.HTTPError as e:
#         print(f"❌ Erro na API Groq: {e}")
#         sys.exit(1)
# ============================================================


def execute_runbook(incident_type: str, alert: dict) -> dict:
    """Importa e executa o runbook apropriado."""
    runbook_module = RUNBOOK_MAP.get(incident_type)
    
    if not runbook_module:
        return {"status": "error", "message": "No runbook available"}
    
    try:
        module = import_module(runbook_module)
        result = module.execute(alert)
        return result
    except Exception as e:
        print(f"❌ Erro ao executar runbook: {e}")
        return {"status": "error", "message": str(e)}


def save_incident_log(alert: dict, incident_type: str, result: dict):
    """Salva log do incidente."""
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
    
    # Também salva JSON para o workflow usar
    with open("incident-result.json", "w") as f:
        json.dump(log_entry, f, indent=2)
    
    print(f"\n📝 Log salvo em: {log_file}")
    print(f"📄 Resultado salvo em: incident-result.json")


def main():
    api_name = "Gemini" if USE_GEMINI else "Groq"
    
    print("\n" + "=" * 60)
    print(f"🤖 ORQUESTRADOR DE INCIDENTES (CI/CD - {api_name} API)")
    print("=" * 60)
    
    if len(sys.argv) < 2:
        print("\n❌ Uso: python incident_handler_ci.py <alerta.json>")
        sys.exit(1)
    
    alert_file = sys.argv[1]
    
    # 1. Carregar alerta
    print(f"\n📂 Carregando: {alert_file}")
    alert = load_alert(alert_file)
    
    print(f"\n🚨 ALERTA:")
    print(f"   ID: {alert.get('alert_id')}")
    print(f"   Severidade: {alert.get('severity', 'unknown').upper()}")
    print(f"   Mensagem: {alert.get('message')}")
    
    # 2. Classificar com IA
    print(f"\n🤖 Classificando com {api_name} API...")
    
    if USE_GEMINI:
        incident_type = classify_with_gemini(alert)
    else:
        # Descomente a função classify_with_groq acima para usar
        # incident_type = classify_with_groq(alert)
        print("❌ Groq não está habilitado. Descomente a função classify_with_groq.")
        sys.exit(1)
    
    print(f"   ✓ Tipo: {incident_type.upper()}")
    print(f"   ✓ Runbook: {RUNBOOK_MAP.get(incident_type)}")
    
    # 3. Executar runbook
    print("\n⚡ Executando runbook...")
    result = execute_runbook(incident_type, alert)
    
    # 4. Salvar log
    save_incident_log(alert, incident_type, result)
    
    # 5. Resumo
    print("\n" + "=" * 60)
    print("📊 RESUMO")
    print("=" * 60)
    print(f"   Status: {result.get('status', 'unknown').upper()}")
    print(f"   Duração: {result.get('duration_seconds', 0)}s")
    print("=" * 60)
    
    # Exit code
    if result.get("status") == "success":
        print("\n✅ INCIDENTE RESOLVIDO!")
        sys.exit(0)
    else:
        print("\n❌ FALHA - Escalar para equipe")
        sys.exit(1)


if __name__ == "__main__":
    main()
