"""
Testes para o módulo usuario.

Estes testes só devem rodar quando src/usuario.py for modificado.
"""
from src.usuario import criar_usuario, validar_email


def test_criar_usuario():
    """Testa criação de usuário."""
    user = criar_usuario("João", "joao@email.com")
    
    assert user["nome"] == "João"
    assert user["email"] == "joao@email.com"
    assert user["ativo"] == True


def test_validar_email_valido():
    """Testa emails válidos."""
    assert validar_email("teste@email.com") == True
    assert validar_email("user@domain.org") == True


def test_validar_email_invalido():
    """Testa emails inválidos."""
    assert validar_email("invalido") == False
    assert validar_email("sem-arroba.com") == False
    assert validar_email("@sem-dominio") == False
