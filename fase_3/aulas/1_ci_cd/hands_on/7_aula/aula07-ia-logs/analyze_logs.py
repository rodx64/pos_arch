#!/usr/bin/env python3
"""
🤖 Analisador de Logs com IA (versão LOCAL)

Este script usa Ollama rodando localmente para analisar
logs da aplicação e identificar problemas.

Uso:
    python analyze_logs.py

Pré-requisitos:
    1. Ollama instalado:
       - macOS: brew install ollama (ou https://ollama.com/download/mac)
       - Linux: curl -fsSL https://ollama.com/install.sh | sh
       - Windows: https://ollama.com/download/windows
    2. Modelo baixado: ollama pull llama3.2
    3. Ollama rodando: ollama serve
"""
import requests
import sys
from pathlib import Path


def read_logs(log_file: str = "logs/app.log") -> str:
    """
    Lê o arquivo de logs.
    
    Args:
        log_file: Caminho para o arquivo de log
        
    Returns:
        Conteúdo do arquivo de log
    """
    log_path = Path(log_file)
    
    if not log_path.exists():
        print(f"❌ Arquivo não encontrado: {log_file}")
        sys.exit(1)
    
    return log_path.read_text()


def analyze_with_ollama(logs: str) -> str:
    """
    Envia logs para Ollama analisar.
    
    Args:
        logs: Conteúdo dos logs
        
    Returns:
        Análise da IA
    """
    
    prompt = f"""Você é um especialista em DevOps e SRE.

Analise os logs abaixo e forneça:

1. **ERROS CRÍTICOS**: Liste os erros mais graves encontrados
2. **PADRÕES PREOCUPANTES**: Identifique sequências que indicam problemas
3. **CAUSA RAIZ PROVÁVEL**: O que provavelmente causou os problemas
4. **RECOMENDAÇÕES**: O que fazer para resolver e prevenir

Seja direto e objetivo. Use emojis para destacar severidade:
- 🔴 Crítico
- 🟡 Atenção
- 🟢 OK

LOGS:
{logs}
"""

    try:
        # Timeout maior para modelos mais lentos (120s)
        response = requests.post(
            "http://localhost:11434/api/generate",
            json={
                "model": "llama3.2",
                "prompt": prompt,
                "stream": False
            },
            timeout=120
        )
        response.raise_for_status()
        return response.json()["response"]
        
    except requests.exceptions.ConnectionError:
        print("❌ Erro: Ollama não está rodando!")
        print("")
        print("Para iniciar o Ollama:")
        print("  1. Abra outro terminal")
        print("  2. Execute: ollama serve")
        print("")
        sys.exit(1)
        
    except requests.exceptions.Timeout:
        print("❌ Erro: Timeout na resposta do Ollama (>120s)")
        print("")
        print("Possíveis soluções:")
        print("  1. Verifique se o Ollama está rodando: ollama serve")
        print("  2. Tente um modelo menor: ollama pull llama3.2:1b")
        print("  3. Reinicie o Ollama e tente novamente")
        print("")
        sys.exit(1)


def count_by_level(logs: str) -> dict:
    """
    Conta logs por nível de severidade.
    
    Args:
        logs: Conteúdo dos logs
        
    Returns:
        Dicionário com contagem por nível
    """
    levels = {
        "INFO": 0,
        "WARN": 0,
        "ERROR": 0,
        "CRITICAL": 0
    }
    
    for line in logs.split("\n"):
        for level in levels:
            if f"[{level}]" in line:
                levels[level] += 1
                break
    
    return levels


def main():
    """Função principal."""
    print("=" * 60)
    print("🤖 Analisador de Logs com IA (Ollama)")
    print("=" * 60)
    print("")
    
    # 1. Ler logs
    print("📂 Lendo arquivo de logs...")
    logs = read_logs()
    
    # 2. Estatísticas básicas
    levels = count_by_level(logs)
    total_lines = len(logs.strip().split("\n"))
    
    print(f"\n📊 Estatísticas:")
    print(f"   Total de linhas: {total_lines}")
    print(f"   🟢 INFO: {levels['INFO']}")
    print(f"   🟡 WARN: {levels['WARN']}")
    print(f"   🔴 ERROR: {levels['ERROR']}")
    print(f"   💀 CRITICAL: {levels['CRITICAL']}")
    
    # 3. Análise com IA
    print("\n🤖 Analisando com IA...")
    print("   ⏳ Aguarde, isso pode levar até 2 minutos...")
    print("-" * 60)
    
    analysis = analyze_with_ollama(logs)
    
    print("\n📋 ANÁLISE DA IA:")
    print("=" * 60)
    print(analysis)
    print("=" * 60)


if __name__ == "__main__":
    main()
