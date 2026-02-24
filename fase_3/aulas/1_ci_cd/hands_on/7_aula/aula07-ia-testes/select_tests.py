#!/usr/bin/env python3
"""
🤖 Seletor de Testes com IA (versão LOCAL)

Este script usa Ollama rodando localmente para analisar
quais arquivos foram modificados e sugerir quais testes rodar.

Uso:
    python select_tests.py

Pré-requisitos:
    1. Ollama instalado:
       - macOS: brew install ollama (ou https://ollama.com/download/mac)
       - Linux: curl -fsSL https://ollama.com/install.sh | sh
       - Windows: https://ollama.com/download/windows
    2. Modelo baixado: ollama pull llama3.2
    3. Ollama rodando: ollama serve
"""
import subprocess
import requests
import sys
from pathlib import Path


def get_available_tests() -> list:
    """Retorna lista de arquivos de teste que existem."""
    tests_dir = Path("tests")
    if not tests_dir.exists():
        return []
    return [str(f) for f in tests_dir.glob("test_*.py")]


def get_changed_files():
    """
    Pega lista de arquivos modificados no último commit.
    
    Usa git diff para comparar com o commit anterior.
    Se não houver commit anterior, lista todos os arquivos.
    """
    try:
        result = subprocess.run(
            ["git", "diff", "--name-only", "HEAD~1"],
            capture_output=True, 
            text=True,
            check=True
        )
        files = result.stdout.strip()
        if files:
            return files
    except subprocess.CalledProcessError:
        pass
    
    # Fallback: listar todos os arquivos tracked
    result = subprocess.run(
        ["git", "ls-files"],
        capture_output=True,
        text=True
    )
    return result.stdout.strip()


def ask_ollama(changed_files: str) -> str:
    """
    Pergunta para IA local (Ollama) quais testes rodar.
    
    Args:
        changed_files: Lista de arquivos modificados
        
    Returns:
        Sugestão da IA sobre quais testes executar
    """
    
    # Lista de testes disponíveis no projeto
    available_tests = get_available_tests()
    
    prompt = f"""Analise os arquivos modificados e selecione APENAS os testes necessários.

ARQUIVOS MODIFICADOS:
{changed_files}

MAPEAMENTO EXATO:
- src/calculadora.py → tests/test_calculadora.py
- src/usuario.py → tests/test_usuario.py
- Arquivos .md, .txt, .gitignore → NENHUM teste
- Arquivos de configuração (select_tests.py, requirements.txt) → NENHUM teste

TESTES DISPONÍVEIS:
{chr(10).join(available_tests)}

INSTRUÇÕES:
1. Analise APENAS arquivos em src/
2. Ignore arquivos de configuração, documentação e scripts
3. Responda SOMENTE com os caminhos dos testes necessários
4. Se nenhum arquivo src/ foi modificado, responda: NENHUM

RESPOSTA (apenas caminhos, um por linha):"""

    try:
        response = requests.post(
            "http://localhost:11434/api/generate",
            json={
                "model": "llama3.2",
                "prompt": prompt,
                "stream": False
            },
            timeout=60
        )
        response.raise_for_status()
        return response.json()["response"].strip()
        
    except requests.exceptions.ConnectionError:
        print("❌ Erro: Ollama não está rodando!")
        print("")
        print("Para iniciar o Ollama:")
        print("  1. Abra outro terminal")
        print("  2. Execute: ollama serve")
        print("")
        sys.exit(1)
        
    except requests.exceptions.Timeout:
        print("❌ Erro: Timeout na resposta do Ollama")
        sys.exit(1)


def get_tests_by_mapping(changed_files: str) -> list:
    """
    Mapeamento determinístico: arquivo fonte → arquivo de teste.
    Usado como fallback ou validação da IA.
    """
    mapping = {
        "src/calculadora.py": "tests/test_calculadora.py",
        "src/usuario.py": "tests/test_usuario.py",
    }
    
    tests = set()
    for file in changed_files.split('\n'):
        file = file.strip()
        # Extrair apenas o caminho relativo ao projeto
        for src, test in mapping.items():
            if src in file:
                if Path(test).exists():
                    tests.add(test)
    
    return list(tests)


def filter_valid_tests(suggestion: str, changed_files: str) -> list:
    """
    Filtra a sugestão da IA para manter apenas arquivos de teste válidos.
    Usa mapeamento determinístico para validar.
    """
    available = set(get_available_tests())
    mapped_tests = set(get_tests_by_mapping(changed_files))
    valid_tests = []
    
    for line in suggestion.split('\n'):
        line = line.strip()
        # Ignorar linhas vazias, comandos, ou explicações
        if not line:
            continue
        if line.startswith('#') or line.startswith('-'):
            continue
        if 'pytest' in line.lower() or 'nenhum' in line.lower():
            continue
        if not line.endswith('.py'):
            continue
        
        # Verificar se o arquivo existe E está no mapeamento esperado
        if line in available and line in mapped_tests:
            valid_tests.append(line)
    
    # Se IA não retornou nada válido, usar mapeamento direto
    if not valid_tests and mapped_tests:
        return list(mapped_tests)
    
    return list(set(valid_tests)) if valid_tests else list(mapped_tests)


def main():
    """Função principal."""
    print("=" * 50)
    print("🤖 Seletor de Testes com IA (Ollama)")
    print("=" * 50)
    print("")
    
    # 1. Pegar arquivos modificados
    print("🔍 Analisando arquivos modificados...")
    changed_files = get_changed_files()
    
    if not changed_files:
        print("ℹ️  Nenhum arquivo modificado encontrado.")
        return
    
    print(f"\n📝 Arquivos modificados:")
    for f in changed_files.split('\n'):
        print(f"   - {f}")
    
    # 2. Consultar IA
    print("\n🤖 Consultando Ollama...")
    suggestion = ask_ollama(changed_files)
    
    # 3. Filtrar apenas testes válidos (validado com mapeamento)
    valid_tests = filter_valid_tests(suggestion, changed_files)
    
    if not valid_tests:
        print("\n⚠️  IA não sugeriu testes válidos. Rodando todos os testes.")
        valid_tests = get_available_tests()
    
    # 4. Mostrar resultado
    print(f"\n✅ Testes a executar:")
    print("-" * 30)
    for test in valid_tests:
        print(f"  {test}")
    print("-" * 30)
    
    # 5. Comando para rodar
    tests_str = " ".join(valid_tests)
    print(f"\n💡 Comando para executar:")
    print(f"   pytest {tests_str} -v")


if __name__ == "__main__":
    main()
