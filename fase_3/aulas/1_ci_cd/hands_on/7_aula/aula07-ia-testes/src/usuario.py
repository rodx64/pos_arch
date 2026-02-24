"""
Módulo de gerenciamento de usuários.

Este módulo demonstra funções de usuário que serão
testadas separadamente da calculadora.
"""


def criar_usuario(nome: str, email: str) -> dict:
    """
    Cria um novo usuário.
    
    Args:
        nome: Nome do usuário
        email: Email do usuário
        
    Returns:
        Dicionário com dados do usuário
    """
    return {
        "nome": nome,
        "email": email,
        "ativo": True
    }


def validar_email(email: str) -> bool:
    """
    Valida formato básico de email.
    
    Args:
        email: Email para validar
        
    Returns:
        True se válido, False caso contrário
    """
    return "@" in email and "." in email

    #Test Feature v1
