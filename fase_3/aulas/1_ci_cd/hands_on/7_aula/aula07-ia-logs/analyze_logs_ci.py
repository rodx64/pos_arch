#!/usr/bin/env python3
"""
🤖 Analisador de Logs com IA (versão CI/CD)

Este script usa a API do Google Gemini (grátis) para analisar
logs no GitHub Actions.

Uso:
    export GEMINI_API_KEY="sua-chave-aqui"
    python analyze_logs_ci.py

Obter chave grátis:
    - Gemini: https://aistudio.google.com/apikey
    - Groq (alternativa): https://console.groq.com
"""
import requests
import os
import sys
import json
from pathlib import Path


# ============================================================
# CONFIGURAÇÃO: Escolha qual API usar
# ============================================================
USE_GEMINI = True  # Mude para False para usar Groq


def read_logs(log_file: str = "logs/app.log") -> str:
    """Lê o arquivo de logs."""
    log_path = Path(log_file)
    
    if not log_path.exists():
        print(f"❌ Arquivo não encontrado: {log_file}")
        sys.exit(1)
    
    return log_path.read_text()


def analyze_with_gemini(logs: str) -> dict:
    """
    Envia logs para Google Gemini analisar.
    
    Retorna análise estruturada em JSON.
    """
    
    api_key = os.environ.get("GEMINI_API_KEY")
    
    if not api_key:
        print("❌ Erro: GEMINI_API_KEY não está configurada!")
        print("")
        print("Para configurar:")
        print("  1. Acesse https://aistudio.google.com/apikey")
        print("  2. Clique em 'Create API Key'")
        print("  3. export GEMINI_API_KEY='sua-chave'")
        print("")
        sys.exit(1)
    
    prompt = f"""Você é um analisador de logs. Analise os logs abaixo e responda APENAS em JSON válido com esta estrutura:
{{
  "status": "critical" ou "warning" ou "ok",
  "errors_found": número de erros encontrados,
  "main_issue": "descrição curta do problema principal",
  "recommendation": "o que fazer para resolver"
}}

Logs para analisar:
{logs}

Responda APENAS o JSON, sem explicações."""

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
                    "maxOutputTokens": 500
                }
            },
            timeout=30
        )
        
        response.raise_for_status()
        content = response.json()["candidates"][0]["content"]["parts"][0]["text"]
        
        # Limpar possíveis marcadores de código
        content = content.strip()
        if content.startswith("```json"):
            content = content[7:]
        if content.startswith("```"):
            content = content[3:]
        if content.endswith("```"):
            content = content[:-3]
        content = content.strip()
        
        # Tentar parsear como JSON
        try:
            return json.loads(content)
        except json.JSONDecodeError:
            return {"raw_response": content}
        
    except requests.exceptions.HTTPError as e:
        print(f"❌ Erro na API Gemini: {e}")
        sys.exit(1)


# ============================================================
# ALTERNATIVA: Groq API (descomente para usar)
# ============================================================
# def analyze_with_groq(logs: str) -> dict:
#     """
#     Envia logs para Groq API analisar.
#     Retorna análise estruturada em JSON.
#     """
#     
#     api_key = os.environ.get("GROQ_API_KEY")
#     
#     if not api_key:
#         print("❌ Erro: GROQ_API_KEY não está configurada!")
#         print("  1. Acesse https://console.groq.com")
#         print("  2. Crie uma API Key")
#         print("  3. export GROQ_API_KEY='sua-chave'")
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
#                         "content": """Você é um analisador de logs. Responda APENAS em JSON válido com esta estrutura:
# {
#   "status": "critical" | "warning" | "ok",
#   "errors_found": número,
#   "main_issue": "descrição curta do problema principal",
#   "recommendation": "o que fazer para resolver"
# }"""
#                     },
#                     {
#                         "role": "user",
#                         "content": f"Analise estes logs:\n\n{logs}"
#                     }
#                 ],
#                 "temperature": 0.1,
#                 "max_tokens": 500
#             },
#             timeout=30
#         )
#         
#         response.raise_for_status()
#         content = response.json()["choices"][0]["message"]["content"]
#         
#         try:
#             return json.loads(content)
#         except json.JSONDecodeError:
#             return {"raw_response": content}
#         
#     except requests.exceptions.HTTPError as e:
#         print(f"❌ Erro na API Groq: {e}")
#         sys.exit(1)
# ============================================================


def count_by_level(logs: str) -> dict:
    """Conta logs por nível de severidade."""
    levels = {"INFO": 0, "WARN": 0, "ERROR": 0, "CRITICAL": 0}
    
    for line in logs.split("\n"):
        for level in levels:
            if f"[{level}]" in line:
                levels[level] += 1
                break
    
    return levels


def main():
    """Função principal para CI."""
    api_name = "Gemini" if USE_GEMINI else "Groq"
    
    print("=" * 60)
    print(f"🤖 Analisador de Logs com IA ({api_name} API)")
    print("=" * 60)
    print("")
    
    # 1. Ler logs
    print("📂 Lendo logs...")
    logs = read_logs()
    
    # 2. Estatísticas
    levels = count_by_level(logs)
    print(f"📊 Encontrados: {levels['ERROR']} erros, {levels['CRITICAL']} críticos")
    
    # 3. Análise com IA
    print(f"\n🤖 Consultando {api_name} API...")
    
    if USE_GEMINI:
        analysis = analyze_with_gemini(logs)
    else:
        # Descomente a função analyze_with_groq acima para usar
        # analysis = analyze_with_groq(logs)
        print("❌ Groq não está habilitado. Descomente a função analyze_with_groq.")
        sys.exit(1)
    
    # 4. Mostrar resultado
    print("\n📋 ANÁLISE:")
    print(json.dumps(analysis, indent=2, ensure_ascii=False))
    
    # 5. Salvar para workflow
    with open("log-analysis.json", "w") as f:
        json.dump(analysis, f, indent=2, ensure_ascii=False)
    
    print("\n📄 Salvo em: log-analysis.json")
    
    # 6. Definir exit code baseado no status
    status = analysis.get("status", "ok")
    if status == "critical":
        print("\n🔴 Status: CRÍTICO - Ação necessária!")
        sys.exit(1)  # Falha o workflow
    elif status == "warning":
        print("\n🟡 Status: ATENÇÃO - Monitorar")
        sys.exit(0)  # Passa mas com aviso
    else:
        print("\n🟢 Status: OK")
        sys.exit(0)


if __name__ == "__main__":
    main()
